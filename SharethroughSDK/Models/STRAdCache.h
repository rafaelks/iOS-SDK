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
- (void)saveAd:(STRAdvertisement *)ad;
- (STRAdvertisement *)fetchCachedAdForPlacementKey:(NSString *)placementKey;
- (BOOL)isAdStale:(NSString *)placementKey;
@end
