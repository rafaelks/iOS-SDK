//
//  STRAdCache.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
@class STRAdvertisement, STRDateProvider, STRAdPlacement, STRAdPlacementInfiniteScrollFields;

@interface STRAdCache : NSObject <NSCacheDelegate>

- (instancetype)initWithDateProvider:(STRDateProvider *)dateProvider;
- (NSUInteger)setAdCacheTimeoutInSeconds:(NSUInteger)seconds;

- (void)saveAds:(NSMutableArray *)creatives forPlacement:(STRAdPlacement *)placement andInitializeAtIndex:(BOOL)initializeIndex;

- (STRAdvertisement *)fetchCachedAdForPlacement:(STRAdPlacement *)placement;
- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey CreativeKey:(NSString *)creativeKey;

- (BOOL)isAdAvailableForPlacement:(STRAdPlacement *)placement;
- (NSUInteger)numberOfAdsAvailableForPlacement:(STRAdPlacement *)placement;
- (BOOL)shouldBeginFetchForPlacement:(NSString *)placementKey;

- (BOOL)pendingAdRequestInProgressForPlacement:(NSString *)placementKey;
- (void)clearPendingAdRequestForPlacement:(NSString *)placementKey;

- (STRAdPlacementInfiniteScrollFields *)getInfiniteScrollFieldsForPlacement:(NSString *)placementKey;
- (void)saveInfiniteScrollFields:(STRAdPlacementInfiniteScrollFields *)fields;
@end
