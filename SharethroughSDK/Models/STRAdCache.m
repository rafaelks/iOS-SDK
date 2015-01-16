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

#import "NSMutableArray+Queue.h"

@interface STRAdCache ()

@property (nonatomic, strong) STRDateProvider     *dateProvider;
@property (nonatomic, assign) NSUInteger          STRPlacementAdCacheTimeoutInSeconds;
@property (nonatomic, strong) NSCache             *cachedCreatives;
@property (nonatomic, strong) NSCache             *cachedIndexToCreativeMaps;
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

        self.cachedCreatives = [[NSCache alloc] init];
        self.cachedCreatives.delegate = self;

        self.cachedIndexToCreativeMaps = [[NSCache alloc] init];
        self.cachedIndexToCreativeMaps.delegate = self;

        self.pendingRequestPlacementKeys = [NSMutableSet set];
        self.cachedPlacementInfiniteScrollFields = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSUInteger)setAdCacheTimeoutInSeconds:(NSUInteger)seconds {
    if (seconds < 20) {
        seconds = 20;
    }
    self.STRPlacementAdCacheTimeoutInSeconds = seconds;
    return self.STRPlacementAdCacheTimeoutInSeconds;
}

- (STRAdvertisement *)fetchCachedAdForPlacement:(STRAdPlacement *)placement {
    NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placement.placementKey];
    return [indexToCreativeMap objectForKey:[NSNumber numberWithLong:placement.adIndex]];
}

- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey CreativeKey:(NSString *)creativeKey {
    NSArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    for (int i = 0; i < [creatives count]; ++i) {
        STRAdvertisement *ad = creatives[i];
        if ([ad.creativeKey isEqualToString:creativeKey]) {
            return ad;
        }
    }
    return nil;
}

- (void)saveAds:(NSMutableArray *)creatives forPlacement:(STRAdPlacement *)placement andInitializeAtIndex:(BOOL)initializeIndex {
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
    if (initializeIndex) {
        NSMutableDictionary *indexToCreativeMap = [self.cachedIndexToCreativeMaps objectForKey:placement.placementKey];
        STRAdvertisement *ad = [cachedCreativesQueue dequeue];
        [indexToCreativeMap setObject:ad forKey:[NSNumber numberWithLong:placement.adIndex]];
    }
    [self clearPendingAdRequestForPlacement:placement.placementKey];
}

- (BOOL)isAdAvailableForPlacement:(STRAdPlacement *)placement {
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
    if (!ad.visibleImpressionTime) {
        return YES;
    }
    NSDate *now = [self.dateProvider now];
    NSTimeInterval timeInterval = [now timeIntervalSinceDate:ad.visibleImpressionTime];

    if (timeInterval == NAN || timeInterval > self.STRPlacementAdCacheTimeoutInSeconds) {
        if ([creatives peek] == nil) {
            return NO;
        } else {
            [indexToCreativeMap setObject:[creatives dequeue] forKey:[NSNumber numberWithLong:placement.adIndex]];
            return YES;
        }
    }
    return YES;
}

- (NSUInteger)numberOfAdsAvailableForPlacement:(STRAdPlacement *)placement {
    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placement.placementKey];
    return [creatives count];
}

- (BOOL)shouldBeginFetchForPlacement:(NSString *)placementKey {
    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    if ([creatives count] <= 1 && ![self pendingAdRequestInProgressForPlacement:placementKey]) {
        return YES;
    }
    return NO;
}

- (BOOL)pendingAdRequestInProgressForPlacement:(NSString *)placementKey {
    NSString *existingPlacementKey = [self.pendingRequestPlacementKeys member:placementKey];
    if (existingPlacementKey == nil) { //not currently being requested
        [self.pendingRequestPlacementKeys addObject:placementKey];
        return NO;
    } else {
        return YES;
    }
}

- (void)clearPendingAdRequestForPlacement:(NSString *)placementKey {
    [self.pendingRequestPlacementKeys removeObject:placementKey];
}

- (STRAdPlacementInfiniteScrollFields *)getInfiniteScrollFieldsForPlacement:(NSString *)placementKey {
    return self.cachedPlacementInfiniteScrollFields[placementKey];
}

- (void)saveInfiniteScrollFields:(STRAdPlacementInfiniteScrollFields *)fields {
    self.cachedPlacementInfiniteScrollFields[fields.placementKey] = fields;
}

#pragma mark - NSCacheDelegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj {
    //TODO: Consider clearing the pKey -> cKey pointer and render timestamp
    NSLog(@"Evicting object %@",obj);
}
@end
