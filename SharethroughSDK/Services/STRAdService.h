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

@class STRRestClient, STRNetworkClient, STRAdCache, STRBeaconService, STRAdPlacement, ASIdentifierManager;

@interface STRAdService : NSObject

- (id)initWithRestClient:(STRRestClient *)restClient
           networkClient:(STRNetworkClient *)networkClient
                 adCache:(STRAdCache *)adCache
           beaconService:(STRBeaconService *)beaconService
     asIdentifierManager:(ASIdentifierManager *)identifierManager;

- (STRPromise *)prefetchAdsForPlacement:(STRAdPlacement *)placement;
- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement;
- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement auctionParameterKey:(NSString *)apKey auctionParameterValue:(NSString *)apValue;
- (BOOL)isAdCachedForPlacement:(STRAdPlacement *)placement;
@end
