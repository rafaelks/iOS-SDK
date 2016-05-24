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

@class STRRestClient, STRNetworkClient, STRAdCache, STRBeaconService, STRAdPlacement, STRAdvertisement, STRInjector, ASIdentifierManager;

@interface STRAdService : NSObject

- (id)initWithRestClient:(STRRestClient *)restClient
           networkClient:(STRNetworkClient *)networkClient
                 adCache:(STRAdCache *)adCache
           beaconService:(STRBeaconService *)beaconService
     asIdentifierManager:(ASIdentifierManager *)identifierManager
                injector:(STRInjector *)injector;

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)initialize;
- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement auctionParameterKey:(NSString *)apKey auctionParameterValue:(NSString *)apValue isPrefetch:(BOOL)prefetch;
- (BOOL)isAdCachedForPlacement:(STRAdPlacement *)placement;

#pragma mark - Methods Exposed only for Testing
- (STRAdvertisement *)adForCreative:(NSDictionary *)creativeJSON inPlacement:(NSDictionary *)placementJSON;
@end
