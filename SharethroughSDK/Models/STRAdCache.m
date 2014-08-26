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

@property (nonatomic, strong) NSMutableDictionary *cachedCreatives;
@property (nonatomic, strong) NSMutableDictionary *cachedPlacementAdPointers;
@property (nonatomic, strong) NSMutableDictionary *cachedTimestamps;
@property (nonatomic, strong) STRDateProvider *dateProvider;

@end

@implementation STRAdCache

//TODO: Clear cached ads after some time

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithDateProvider:(STRDateProvider *)dateProvider {
    self = [super init];
    if (self) {
        self.cachedCreatives = [NSMutableDictionary dictionary];
        self.cachedPlacementAdPointers = [NSMutableDictionary dictionary];
        self.cachedTimestamps = [NSMutableDictionary dictionary];
        self.dateProvider = dateProvider;
    }
    return self;
}

- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey {
    NSString *creativeKey = self.cachedPlacementAdPointers[placementKey];
    self.cachedTimestamps[creativeKey] = [self.dateProvider now];
    return self.cachedCreatives[creativeKey];
}

- (STRAdvertisement *)fetchCachedAdForCreativeKey:(NSString *)creativeKey {
    self.cachedTimestamps[creativeKey] = [self.dateProvider now];
    return self.cachedCreatives[creativeKey];
}

- (void)saveAd:(STRAdvertisement *)ad {
    self.cachedCreatives[ad.creativeKey] = ad;
    self.cachedPlacementAdPointers[ad.placementKey] = ad.creativeKey;
    self.cachedTimestamps[ad.creativeKey] = [self.dateProvider now];
}

- (BOOL)isAdStale:(NSString *)placementKey {
    NSString *creativeKey = self.cachedPlacementAdPointers[placementKey];
    NSDate *cacheDate = self.cachedTimestamps[creativeKey];
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
