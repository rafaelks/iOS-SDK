//
//  STRAsapService.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 5/10/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSInteger kRequestInProgress;

@class STRRestClient, STRAdCache, STRInjector, STRAdPlacement, STRPromise, STRMediationService, ASIdentifierManager;

@interface STRAsapService : NSObject

- (id)initWithRestClient:(STRRestClient *)restClient
                 adCache:(STRAdCache *)adCache
               mediationService:(STRMediationService *)mediationService
     asIdentifierManager:(ASIdentifierManager *)identifierManager
                  device:(UIDevice *)device
                injector:(STRInjector *)injector;

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)prefetch;

@end
