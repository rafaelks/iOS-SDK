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
#import "STRAdPlacement.h"
#import "STRLogging.h"

#import "NSMutableArray+Queue.h"
#import "UIView+Visible.h"

@interface STRAdCache ()

@property (nonatomic, strong) STRDateProvider     *dateProvider;
@property (nonatomic, assign) NSUInteger          STRPlacementAdCacheTimeoutInSeconds;
@property (nonatomic, strong) NSMutableDictionary *cachedCreatives;
@property (nonatomic, strong) NSMutableDictionary *cachedIndexToCreativeMaps;
@property (nonatomic, strong) NSMutableSet        *pendingRequestPlacementKeys;

@property (nonatomic, strong) NSMutableDictionary *cachedPlacementInfiniteScrollFields;
@end

@implementation STRAdCache

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithDateProvider:(STRDateProvider *)dateProvider {
    self = [super init];
    if (self) {
        self.dateProvider = dateProvider;
        self.STRPlacementAdCacheTimeoutInSeconds = 20;

        self.cachedCreatives = [[NSMutableDictionary alloc] init];

        self.cachedIndexToCreativeMaps = [[NSMutableDictionary alloc] init];

        self.pendingRequestPlacementKeys = [NSMutableSet set];
        self.cachedPlacementInfiniteScrollFields = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSUInteger)setAdCacheTimeoutInSeconds:(NSUInteger)seconds {
    TLog(@"seconds:%tu", seconds);
    if (seconds < 20) {
        seconds = 20;
    }
    self.STRPlacementAdCacheTimeoutInSeconds = seconds;
    return self.STRPlacementAdCacheTimeoutInSeconds;
}

- (void)saveAds:(NSMutableArray *)creatives forPlacement:(STRAdPlacement *)placement andInitializeAtIndex:(BOOL)initializeIndex {
    TLog(@"placementKey:%@, initialize:%@", placement.placementKey, initializeIndex ? @"YES" : @"NO");
    NSMutableArray *cachedCreativesQueue = [self.cachedCreatives objectForKey:placement.placementKey];
    if (cachedCreativesQueue == nil) {
        cachedCreativesQueue = creatives;
        [self.cachedCreatives setObject:creatives forKey:placement.placementKey];
    } else {
        for (int i = 0; i < [creatives count]; ++i) {
            [cachedCreativesQueue enqueue:creatives[i]];
        }
        [self.cachedCreatives setObject:cachedCreativesQueue forKey:placement.placementKey];
    }
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placement.placementKey];
    if (indexToCreativeMap == nil) {
        indexToCreativeMap = [[NSMutableDictionary alloc] init];
        [self.cachedIndexToCreativeMaps setObject:indexToCreativeMap forKey:placement.placementKey];
    }
    if (initializeIndex) {
        STRAdvertisement *ad = [cachedCreativesQueue dequeue];
        [indexToCreativeMap setObject:ad forKey:[NSNumber numberWithLong:placement.adIndex]];
    }
    [self clearPendingAdRequestForPlacement:placement.placementKey];
}

- (STRAdvertisement *)fetchCachedAdForPlacement:(STRAdPlacement *)placement {
    TLog(@"pkey:%@",placement.placementKey);
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placement.placementKey];
    return [indexToCreativeMap objectForKey:[NSNumber numberWithLong:placement.adIndex]];
}

- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey CreativeKey:(NSString *)creativeKey {
    TLog(@"pkey:%@ ckey:%@", placementKey, creativeKey);
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placementKey];
    for (id key in indexToCreativeMap) {
        STRAdvertisement *ad = [indexToCreativeMap objectForKey:key];
        if ([ad.creativeKey isEqualToString:creativeKey]) {
            return ad;
        }
    }
    NSArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    for (int i = 0; i < [creatives count]; ++i) {
        STRAdvertisement *ad = creatives[i];
        if ([ad.creativeKey isEqualToString:creativeKey]) {
            return ad;
        }
    }
    return nil;
}

- (BOOL)isAdAvailableForPlacement:(STRAdPlacement *)placement {
    TLog(@"pkey:%@",placement.placementKey);
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placement.placementKey];
    if (indexToCreativeMap == nil) {
        indexToCreativeMap = [[NSMutableDictionary alloc] init];
        [self.cachedIndexToCreativeMaps setObject:indexToCreativeMap forKey:placement.placementKey];
        return NO;
    }

    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placement.placementKey];
    STRAdvertisement *ad = [indexToCreativeMap objectForKey:[NSNumber numberWithLong:placement.adIndex]];
    if (ad == nil) {
        if ([creatives peek] == nil) {
            return NO;
        } else {
            [indexToCreativeMap setObject:[creatives dequeue] forKey:[NSNumber numberWithLong:placement.adIndex]];
            return YES;
        }
    }

    if (![self isAdExpired:ad]) {
        return YES;
    }
    if ([placement.adView percentVisible] < 0.1f) {
        if ([creatives peek] == nil) {
            return YES; //reuse the old ad
        } else {
            [indexToCreativeMap setObject:[creatives dequeue] forKey:[NSNumber numberWithLong:placement.adIndex]];
            return YES;
        }
    }
    return YES;
}

- (BOOL)isAdExpired:(STRAdvertisement *)ad {
    if (!ad.visibleImpressionTime) { //haven't started the timer yet
        return NO;
    }
    NSDate *now = [self.dateProvider now];
    NSTimeInterval timeInterval = [now timeIntervalSinceDate:ad.visibleImpressionTime];
    if (timeInterval == NAN || timeInterval > self.STRPlacementAdCacheTimeoutInSeconds) {
        return YES;
    }
    return NO;
}

- (NSInteger)numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:(NSString *)placementKey {
    NSMutableArray *queuedCreatives = [self.cachedCreatives objectForKey:placementKey];
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placementKey];

    __block NSUInteger expiredAdsCount = 0;
    [indexToCreativeMap enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        STRAdvertisement *ad = (STRAdvertisement *)obj;
        if ([self isAdExpired:ad]) {
            ++expiredAdsCount;
        }
    }];

    NSUInteger queuedCount = [queuedCreatives count];
    NSUInteger assignedAdsCount = [indexToCreativeMap count];
    NSUInteger effectiveCount;
    if (expiredAdsCount >= queuedCount) {
        effectiveCount = assignedAdsCount;
    } else {
        effectiveCount = assignedAdsCount + queuedCount - expiredAdsCount;
    }
    TLog(@"pkey:%@ assignedCount:%tu, expiredCount:%tu, queuedCount:%tu, effectiveCount:%tu", placementKey, assignedAdsCount, expiredAdsCount, queuedCount, effectiveCount);
    return effectiveCount;
}

- (NSArray *)assignedAdIndixesForPlacementKey:(NSString *)placementKey {
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placementKey];
    NSArray *assignedKeys = [indexToCreativeMap allKeys];
    TLog(@"pkey:%@ assignedKeys:%@",placementKey, assignedKeys);
    return assignedKeys;
}

- (BOOL)shouldBeginFetchForPlacement:(NSString *)placementKey {
    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    if ([creatives count] <= 1 && ![self pendingAdRequestInProgressForPlacement:placementKey]) {
        TLog(@"Should actually begin for pkey:%@",placementKey);
        return YES;
    }
    TLog(@"Should NOT begin fetch for pkey:%@",placementKey);
    return NO;
}

- (BOOL)pendingAdRequestInProgressForPlacement:(NSString *)placementKey {
    NSString *existingPlacementKey = [self.pendingRequestPlacementKeys member:placementKey];
    if (existingPlacementKey == nil) { //not currently being requested
        [self.pendingRequestPlacementKeys addObject:placementKey];
        TLog(@"No request in progress for pkey:%@",placementKey);
        return NO;
    } else {
        TLog(@"Request in progress for pkey:%@",placementKey);
        return YES;
    }
}

- (void)clearPendingAdRequestForPlacement:(NSString *)placementKey {
    TLog(@"pkey:%@",placementKey);
    [self.pendingRequestPlacementKeys removeObject:placementKey];
}

- (STRAdPlacementInfiniteScrollFields *)getInfiniteScrollFieldsForPlacement:(NSString *)placementKey {
    TLog(@"pkey:%@",placementKey);
    return self.cachedPlacementInfiniteScrollFields[placementKey];
}

- (void)saveInfiniteScrollFields:(STRAdPlacementInfiniteScrollFields *)fields {
    TLog(@"");
    self.cachedPlacementInfiniteScrollFields[fields.placementKey] = fields;
}

@end
