//
//  STRAdCache.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
@class STRAdvertisement, STRDateProvider, STRAdPlacement;

@interface STRAdCache : NSObject

- (instancetype)initWithDateProvider:(STRDateProvider *)dateProvider;

- (void)saveAds:(NSMutableArray *)creatives forPlacement:(STRAdPlacement *)placement andAssignAds:(BOOL)assignAds;

- (STRAdvertisement *)fetchCachedAdForPlacement:(STRAdPlacement *)placement;
- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey CreativeKey:(NSString *)creativeKey;

- (BOOL)isAdAvailableForPlacement:(STRAdPlacement *)placement AndInitializeAd:(BOOL)initialize;

- (NSInteger)numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:(NSString *)placementKey;
- (NSInteger)numberOfUnassignedAdsInQueueForPlacementKey:(NSString *)placementKey;
- (NSArray *)assignedAdIndixesForPlacementKey:(NSString *)placementKey;

- (void)clearAssignedAdsForPlacement:(NSString *)placementKey;

- (BOOL)shouldBeginFetchForPlacement:(NSString *)placementKey;

- (BOOL)pendingAdRequestInProgressForPlacement:(NSString *)placementKey;
- (void)clearPendingAdRequestForPlacement:(NSString *)placementKey;

@end
