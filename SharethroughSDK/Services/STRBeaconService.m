//
//  STRBeaconService.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRDateProvider.h"
#import "STRSession.h"
#import <AdSupport/AdSupport.h>
#import "STRAdvertisement.h"

@interface STRBeaconService ()

@property (strong, nonatomic) STRRestClient *restClient;
@property (strong, nonatomic) STRDateProvider *dateProvider;
@property (weak, nonatomic) ASIdentifierManager *identifierManager;

@end

@implementation STRBeaconService

- (id)initWithRestClient:(STRRestClient *)restClient dateProvider:(STRDateProvider *)dateProvider asIdentifierManager:(ASIdentifierManager *)identifierManager {
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.dateProvider = dateProvider;
        self.identifierManager = identifierManager;
    }
    return self;
}

- (void)fireImpressionRequestForPlacementKey:(NSString *)placementKey {
    NSDictionary *uniqueParameters = @{@"pkey": placementKey,
                                       @"type": @"impressionRequest"};
    NSMutableDictionary *parameters = [self commonParameters];
    [parameters addEntriesFromDictionary:uniqueParameters];
    
    [self.restClient sendBeaconWithParameters:parameters];
}


- (void)fireVisibleImpressionForPlacementKey:(NSString *)placementKey ad:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    NSDictionary *uniqueParameters = @{@"pkey": placementKey,
                                       @"type": @"visible"};

    NSMutableDictionary *parameters = [self impressionParametersForAd:ad adSize:adSize];
    [parameters addEntriesFromDictionary:uniqueParameters];

    [self.restClient sendBeaconWithParameters:parameters];
}

- (void)fireImpressionForPlacementKey:(NSString *)placementKey ad:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    NSDictionary *uniqueParameters = @{@"pkey": placementKey,
                                       @"type": @"impression"};

    NSMutableDictionary *parameters = [self impressionParametersForAd:ad adSize:adSize];
    [parameters addEntriesFromDictionary:uniqueParameters];

    [self.restClient sendBeaconWithParameters:parameters];
}

#pragma mark - Private

- (NSMutableDictionary *)impressionParametersForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    NSMutableDictionary *params = [@{@"vkey": ad.variantKey,
                                     @"ckey": ad.creativeKey,
                                     @"pwidth": [NSString stringWithFormat:@"%g", adSize.width],
                                     @"pheight": [NSString stringWithFormat:@"%g", adSize.height]}
                                   mutableCopy];
    [params addEntriesFromDictionary:[self commonParameters]];

    return params;
}

- (NSMutableDictionary *)commonParameters {
    CGRect screenFrame = [[UIScreen mainScreen] bounds];

    return [@{@"bwidth" : [NSString stringWithFormat:@"%g", CGRectGetWidth(screenFrame)],
              @"bheight": [NSString stringWithFormat:@"%g", CGRectGetHeight(screenFrame)],
              @"umtime" : [NSString stringWithFormat:@"%lli", self.dateProvider.millisecondsSince1970],
              @"session": [STRSession sessionToken],
              @"uid"    : [[self.identifierManager advertisingIdentifier] UUIDString]} mutableCopy];
}

@end
