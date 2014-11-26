//
//  STRAdCache.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
@class STRAdvertisement, STRDateProvider;

@interface STRAdCache : NSObject

- (instancetype)initWithDateProvider:(STRDateProvider *)dateProvider;
- (NSUInteger)setAdCacheTimeoutInSeconds:(NSUInteger)seconds;
- (void)saveAd:(STRAdvertisement *)ad;
- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey;
- (STRAdvertisement *)fetchCachedAdForCreativeKey:(NSString *)creativeKey;
- (BOOL)isAdStale:(NSString *)placementKey;

- (BOOL)pendingAdRequestInProgressForPlacement:(NSString *)placementKey;
- (void)clearPendingAdRequestForPlacement:(NSString *)placementKey;
@end
