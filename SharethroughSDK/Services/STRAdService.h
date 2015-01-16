//
//  STRAdService.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRPromise.h"

extern const NSInteger kRequestInProgress;

@class STRRestClient, STRNetworkClient, STRAdCache, STRBeaconService, STRAdPlacement;

@interface STRAdService : NSObject

- (id)initWithRestClient:(STRRestClient *)restClient
           networkClient:(STRNetworkClient *)networkClient
                 adCache:(STRAdCache *)adCache
           beaconService:(STRBeaconService *)beaconService;
- (STRPromise *)prefetchAdsForPlacementKey:(NSString *)placementKey;
- (STRPromise *)prefetchAdsForPlacement:(STRAdPlacement *)placement;
- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement;
- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement creativeKey:(NSString *)creativeKey;
- (BOOL)isAdCachedForPlacement:(STRAdPlacement *)placement;
- (NSUInteger)numberOfAdsForPlacement:(STRAdPlacement *)placement;

@end
