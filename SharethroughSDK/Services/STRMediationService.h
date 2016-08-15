//
//  STRMediationService.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRInjector, STRPromise, STRAdPlacement;

@interface STRMediationService : NSObject


- (id) initWithInjector:(STRInjector *)injector;

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement withParameters:(NSDictionary *)asapResponse;

@end
