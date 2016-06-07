//
//  STRAsapService.m
//  SharethroughSDK
//
//  Created by Peter Kinmond on 5/10/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "STRAsapService.h"

#import <AdSupport/AdSupport.h>

#import "STRAdCache.h"
#import "STRAdPlacement.h"
#import "STRAdService.h"
#import "STRDeferred.h"
#import "STRLogging.h"
#import "STRPromise.h"
#import "STRRestClient.h"

@interface STRAsapService ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRAdCache *adCache;
@property (nonatomic, weak) ASIdentifierManager *identifierManager;
@property (nonatomic, weak) UIDevice *device;
@property (nonatomic, weak) STRInjector *injector;

@end

@implementation STRAsapService


- (id)initWithRestClient:(STRRestClient *)restClient
                 adCache:(STRAdCache *)adCache
               adService:(STRAdService *)adService
     asIdentifierManager:(ASIdentifierManager *)identifierManager
                  device:(UIDevice *)device
                injector:(STRInjector *)injector
{
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.adCache = adCache;
        self.adService = adService;
        self.identifierManager = identifierManager;
        self.device = device;
        self.injector = injector;
    }
    
    return self;
}

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)prefetch{
    TLog(@"pkey: %@, isPrefetch?: %@", placement.placementKey, prefetch ? @"YES" : @"NO");
    if ([self.adCache isAdAvailableForPlacement:placement AndInitializeAd:!prefetch]) {
        STRDeferred *deferred = [STRDeferred defer];
        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacement:placement];
        [deferred resolveWithValue:cachedAd];
        if ([self.adCache shouldBeginFetchForPlacement:placement.placementKey]) {
            [self requestAsapInfoForPlacement:placement isPrefetch:YES];
        }

        return deferred.promise;
    }

    if ([self.adCache pendingAdRequestInProgressForPlacement:placement.placementKey]) {
        return [self requestInProgressError];
    }

    return [self requestAsapInfoForPlacement:placement isPrefetch:prefetch];
}

- (STRPromise *)requestAsapInfoForPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)prefetch{
    STRDeferred *deferred = [STRDeferred defer];
    STRPromise *asapResponse = [self.restClient getAsapInfoWithParameters:[self getParameters:placement]];
    [asapResponse then:^id(NSDictionary *value) {
        NSString *status = value[@"status"];
        if (![status isEqualToString:@"OK"]) {
            NSLog(@"%@",status);
            [deferred rejectWithError:[NSError errorWithDomain:status code:500 userInfo:nil]];
            return nil;
        }
        [self callAdServiceWithParameters:value forPlacement:placement withDeferred:deferred isPrefetch:prefetch];
        return nil;
    } error:^id(NSError *error) {
        [deferred rejectWithError:error];
        return error;
    }];
    return deferred.promise;
}

- (NSDictionary *)getParameters:(STRAdPlacement *)placement {
    NSString *pubAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    NSString *pubAppVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *model = [self.device model];
    NSString *make = @"Apple";
    NSString *os = [self.device systemVersion];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *deviceId = @"";
    NSString *doNotTrack = [self.identifierManager isAdvertisingTrackingEnabled] ? @"false" : @"true";
    if ([self.identifierManager isAdvertisingTrackingEnabled]) {
        deviceId = [[self.identifierManager advertisingIdentifier] UUIDString];
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary: @{
                                                                                       @"pubAppName": pubAppName ?: @"",
                                                                                       @"pubAppVersion": pubAppVersion ?: @"",
                                                                                       @"doNotTrack": doNotTrack ?: @"",
                                                                                       @"language": language ?: @"",
                                                                                       @"make": make ?: @"",
                                                                                       @"model": model ?: @"",
                                                                                       @"os": os ?: @"",
                                                                                       @"deviceId": deviceId ?: @"",
                                                                                       @"pkey": placement.placementKey
                                                                                       }];

    for (id key in placement.customProperties) {
        NSString *customParamKey = [NSString stringWithFormat:@"customKeys[%@]", key];
        [parameters setObject:[placement.customProperties objectForKey:key] forKey:customParamKey];
    }

    return parameters;
}


- (void)callAdServiceWithParameters:(NSDictionary *)value forPlacement:(STRAdPlacement *)placement
                       withDeferred:(STRDeferred *)deferred
             isPrefetch:(BOOL)prefetch{
    NSString *keyType = value[@"keyType"];
    NSString *keyValue = value[@"keyValue"];
    placement.mrid = value[@"mrid"];
    STRPromise *stxPromise;
    
    BOOL directSold = [self isDirectSold:keyType];
    TLog(@"mrid: %@, pkey: %@, keyType:%@, keyValue:%@, directSold:%@, isPrefetch:%@",
         placement.mrid, placement.placementKey, keyType, keyValue, directSold ? @"YES" : @"NO",
         prefetch ? @"YES" : @"NO");

    if (directSold) {
        stxPromise = [self.adService fetchAdForPlacement:placement auctionParameterKey:keyType auctionParameterValue:keyValue isPrefetch:prefetch];
    } else {
        stxPromise = [self.adService fetchAdForPlacement:placement isPrefetch:prefetch];
    }
    
    [stxPromise then:^id(id value) {
        [self.adCache clearPendingAdRequestForPlacement:placement.placementKey];
        [deferred resolveWithValue:value];
        return value;
    } error:^id(NSError *error) {
        [self.adCache clearPendingAdRequestForPlacement:placement.placementKey];
        [deferred rejectWithError:error];
        return error;
    }];
}

- (BOOL)isDirectSold:(NSString *)keyType {
    return [keyType isEqualToString:@"creative_key"] || [keyType isEqualToString:@"campaign_key"];
}


- (STRPromise *)requestInProgressError {
    TLog(@"");
    STRDeferred *deferred = [STRDeferred defer];
    [deferred rejectWithError:[NSError errorWithDomain:@"STR Request in Progress" code:kRequestInProgress userInfo:nil]];
    return deferred.promise;
}

@end
