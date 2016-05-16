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

    if ([self.adCache isAdAvailableForPlacement:placement AndInitializeAd:YES]) {
        STRDeferred *deferred = [STRDeferred defer];
        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacement:placement];
        [deferred resolveWithValue:cachedAd];
        //TODO: how to determine if direct sold?
        if (/*!placement.isDirectSold &&*/ [self.adCache shouldBeginFetchForPlacement:placement.placementKey]) {
            [self.adService fetchAdForPlacement:placement isPrefetch:YES];
        }

        return deferred.promise;
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
    
    return @{
             @"pubAppName": pubAppName ?: @"",
             @"pubAppVersion": pubAppVersion ?: @"",
             @"doNotTrack": doNotTrack ?: @"",
             @"language": language ?: @"",
             @"make": make ?: @"",
             @"model": model ?: @"",
             @"os": os ?: @"",
             @"deviceId": deviceId ?: @"",
             @"pkey": placement.placementKey,
            };
}


- (void)callAdServiceWithParameters:(NSDictionary *)value forPlacement:(STRAdPlacement *)placement
                       withDeferred:(STRDeferred *)deferred
             isPrefetch:(BOOL)prefetch{
    NSString *keyType = value[@"keyType"];
    NSString *keyValue = value[@"keyValue"];
    STRPromise *stxPromise;
    
    BOOL directSold = [self isDirectSold:keyType];
    TLog(@"pkey: %@, keyType:%@, keyValue:%@, directSold:%@", placement.placementKey, keyType, keyValue, directSold ? @"YES" : @"NO");
    
    if (directSold) {
        stxPromise = [self.adService fetchAdForPlacement:placement auctionParameterKey:keyType auctionParameterValue:keyValue];
    } else {
        stxPromise = [self.adService fetchAdForPlacement:placement isPrefetch:prefetch];
    }
    
    [stxPromise then:^id(id value) {
        [deferred resolveWithValue:value];
        return value;
    } error:^id(NSError *error) {
        [deferred rejectWithError:error];
        return error;
    }];
}

- (BOOL)isDirectSold:(NSString *)keyType {
    return [keyType isEqualToString:@"creative_key"] || [keyType isEqualToString:@"campaign_key"];
}

@end
