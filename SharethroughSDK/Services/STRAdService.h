//
//  STRAdService.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRPromise.h"

@class STRRestClient, STRNetworkClient, STRAdCache;

@interface STRAdService : NSObject

- (id)initWithRestClient:(STRRestClient *)restClient networkClient:(STRNetworkClient *)networkClient adCache:(STRAdCache *)adCache;
- (STRPromise *)fetchAdForPlacementKey:(NSString *)placementKey;

@end
