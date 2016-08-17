//
//  STRMediationService.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRInjector, STRPromise, STRAdPlacement, STRDeferred;

@interface STRMediationService : NSObject


- (id) initWithInjector:(STRInjector *)injector;

- (void)fetchAdForPlacement:(STRAdPlacement *)placement withParameters:(NSDictionary *)asapResponse forDeferred:(STRDeferred *)deferred;

@end
