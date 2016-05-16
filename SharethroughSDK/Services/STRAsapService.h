//
//  STRAsapService.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 5/10/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRRestClient, STRAdCache, STRInjector, STRAdPlacement, STRPromise, STRAdService, ASIdentifierManager;

@interface STRAsapService : NSObject

- (id)initWithRestClient:(STRRestClient *)restClient
                 adCache:(STRAdCache *)adCache
               adService:(STRAdService *)adService
     asIdentifierManager:(ASIdentifierManager *)identifierManager
                  device:(UIDevice *)device
                injector:(STRInjector *)injector;

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)prefetch;

@end
