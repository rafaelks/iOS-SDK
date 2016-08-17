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

        self.cachedCreatives = [[NSMutableDictionary alloc] init];

        self.cachedIndexToCreativeMaps = [[NSMutableDictionary alloc] init];

        self.pendingRequestPlacementKeys = [NSMutableSet set];
        self.cachedPlacementInfiniteScrollFields = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveAds:(NSMutableArray *)creatives forPlacement:(STRAdPlacement *)placement andAssignAds:(BOOL)assignAds {
    TLog(@"placementKey:%@, assignAds:%@", placement.placementKey, assignAds ? @"YES" : @"NO");
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
    if (assignAds) {
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

- (BOOL)isAdAvailableForPlacement:(STRAdPlacement *)placement AndInitializeAd:(BOOL)initialize {
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
            if (initialize) {
                ad = [creatives dequeue];
                TLog(@"Setting ad:%@ for index:%lu", ad, (long)placement.adIndex);
                [indexToCreativeMap setObject:ad forKey:[NSNumber numberWithLong:placement.adIndex]];
            }
            return YES;
        }
    }

    if ([placement.adView percentVisible] < 0.1f) {
        if ([creatives peek] == nil) {
            return YES; //reuse the old ad
        } else {
            if (initialize) {
                ad = [creatives dequeue];
                TLog(@"Setting ad:%@ for index:%lu", ad, (long)placement.adIndex);
                [indexToCreativeMap setObject:ad forKey:[NSNumber numberWithLong:placement.adIndex]];
            }
            return YES;
        }
    }
    return YES;
}

- (NSInteger)numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:(NSString *)placementKey {
    NSMutableArray *queuedCreatives = [self.cachedCreatives objectForKey:placementKey];
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placementKey];

    NSUInteger queuedCount = [queuedCreatives count];
    NSUInteger assignedAdsCount = [indexToCreativeMap count];
    NSUInteger effectiveCount;
    effectiveCount = assignedAdsCount + queuedCount;
    TLog(@"pkey:%@ assignedCount:%tu, queuedCount:%tu, effectiveCount:%tu", placementKey, assignedAdsCount, queuedCount, effectiveCount);
    return effectiveCount;
}

- (NSInteger)numberOfUnassignedAdsInQueueForPlacementKey:(NSString *)placementKey {
    NSMutableArray *queuedCreatives = [self.cachedCreatives objectForKey:placementKey];
    NSUInteger queuedCount = [queuedCreatives count];
    TLog(@"pkey:%@, queuedCount:%tu", placementKey, queuedCount);
    return queuedCount;
}

- (NSArray *)assignedAdIndixesForPlacementKey:(NSString *)placementKey {
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placementKey];
    NSArray *assignedKeys = [indexToCreativeMap allKeys];
    TLog(@"pkey:%@ assignedKeys:%@",placementKey, assignedKeys);
    return assignedKeys;
}

- (void)clearAssignedAdsForPlacement:(NSString *)placementKey {
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placementKey];
    [indexToCreativeMap removeAllObjects];
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

@end
