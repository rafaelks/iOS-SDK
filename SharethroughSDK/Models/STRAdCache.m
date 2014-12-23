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
        self.STRPlacementAdCacheTimeoutInSeconds = 10;

        self.cachedCreatives = [[NSCache alloc] init];
        self.cachedCreatives.countLimit = 10;
        self.cachedCreatives.delegate = self;

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

- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey {
    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    return [creatives peek];
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

- (void)saveAds:(NSMutableArray *)creatives forPlacementKey:(NSString *)placementKey {
    NSMutableArray *cachedCreativesQueue = [self.cachedCreatives objectForKey:placementKey];
    if (cachedCreativesQueue == nil) {
        [self.cachedCreatives setObject:creatives forKey:placementKey];
    } else {
        for (int i = 0; i < [creatives count]; ++i) {
            [cachedCreativesQueue enqueue:creatives[i]];
        }
        [self.cachedCreatives setObject:cachedCreativesQueue forKey:placementKey];
    }
    [self clearPendingAdRequestForPlacement:placementKey];
}

- (BOOL)isAdAvailableForPlacement:(NSString *)placementKey {
    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    STRAdvertisement *ad = [creatives peek];
    if (ad == nil) {
        NSLog(@"Ad nil");
        return NO;
    }
    if (!ad.visibleImpressionTime) {
        NSLog(@"Ad not seen yet");
        return YES;
    }
    NSDate *now = [self.dateProvider now];
    NSTimeInterval timeInterval = [now timeIntervalSinceDate:ad.visibleImpressionTime];

    if (timeInterval == NAN || timeInterval > self.STRPlacementAdCacheTimeoutInSeconds) {
        NSLog(@"Past time stamp");
        [creatives dequeue];
        if ([creatives peek] == nil) {
            NSLog(@"No more creatives");
            return NO;
        } else {
            return YES;
        }
    }
    NSLog(@"Ad seen but not for long enough");
    return YES;
}

- (BOOL)shouldBeginFetchForPlacement:(NSString *)placementKey {
    NSMutableArray *creatives = [self.cachedCreatives objectForKey:placementKey];
    if ([creatives count] <= 1 && ![self pendingAdRequestInProgressForPlacement:placementKey]) {
        NSLog(@"Should start fetching because count is %ld", (long)[creatives count]);
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
    STRAdPlacementInfiniteScrollFields *fields = self.cachedPlacementInfiniteScrollFields[placementKey];
    if (fields == nil) {
        fields = [[STRAdPlacementInfiniteScrollFields alloc] init];
        fields.placementKey = placementKey;
        fields.creativeArrayIndex = 0;
        [self saveInfiniteScrollFields:fields];
    }
    return fields;
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
