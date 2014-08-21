//
//  STRAdCache.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdCache.h"
#import "STRAdvertisement.h"
#import "STRDateProvider.h"

const NSInteger STRAdCacheTimeoutInSeconds = 120;

@interface STRAdCache ()

@property (nonatomic, strong) NSMutableDictionary *cachedAds;
@property (nonatomic, strong) NSMutableDictionary *cachedTimestamps;
@property (nonatomic, strong) STRDateProvider *dateProvider;

@end

@implementation STRAdCache

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithDateProvider:(STRDateProvider *)dateProvider {
    self = [super init];
    if (self) {
        self.cachedAds = [NSMutableDictionary dictionary];
        self.cachedTimestamps = [NSMutableDictionary dictionary];
        self.dateProvider = dateProvider;
    }
    return self;
}

- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey {
    return self.cachedAds[placementKey];
}

- (void)saveAd:(STRAdvertisement *)ad {
    self.cachedAds[ad.placementKey] = ad;
    self.cachedTimestamps[ad.placementKey] = [self.dateProvider now];
}

- (BOOL)isAdStale:(NSString *)placementKey {
    NSDate *cacheDate = self.cachedTimestamps[placementKey];
    if (!cacheDate) {
        return YES;
    }
    NSDate *now = [self.dateProvider now];
    NSTimeInterval timeInterval = [now timeIntervalSinceDate:cacheDate];

    if (timeInterval == NAN || timeInterval > STRAdCacheTimeoutInSeconds) {
        return YES;
    }
    return NO;
}

@end
