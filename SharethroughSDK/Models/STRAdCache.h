//
//  STRAdCache.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
@class STRAdvertisement, STRDateProvider, STRAdPlacementInfiniteScrollFields;

@interface STRAdCache : NSObject <NSCacheDelegate>

- (instancetype)initWithDateProvider:(STRDateProvider *)dateProvider;
- (NSUInteger)setAdCacheTimeoutInSeconds:(NSUInteger)seconds;

- (void)saveAds:(NSMutableArray *)creatives forPlacementKey:(NSString *)placementKey;

- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey;
- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey CreativeKey:(NSString *)creativeKey;

- (BOOL)isAdAvailableForPlacement:(NSString *)placementKey;
- (BOOL)shouldBeginFetchForPlacement:(NSString *)placementKey;

- (BOOL)pendingAdRequestInProgressForPlacement:(NSString *)placementKey;
- (void)clearPendingAdRequestForPlacement:(NSString *)placementKey;

- (STRAdPlacementInfiniteScrollFields *)getInfiniteScrollFieldsForPlacement:(NSString *)placementKey;
- (void)saveInfiniteScrollFields:(STRAdPlacementInfiniteScrollFields *)fields;
@end
