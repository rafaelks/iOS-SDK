//
//  STRDFPAdGenerator.h
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRAdPlacement.h"

#import "GADBannerViewDelegate.h"

@protocol STRAdView, STRAdViewDelegate;
@class STRAdService, STRBeaconService, STRInjector, STRPromise, STRRestClient;

extern char const * const STRDFPAdGeneratorKey;

@interface STRDFPAdGenerator : NSObject

- (id)initWithAdService:(STRAdService *)adService
               injector:(STRInjector *)injector
             restClient:(STRRestClient *)restClient;

- (void)placeAdInPlacement:(STRAdPlacement *)placement;

/*
- (STRPromise *)prefetchAdForPlacement:(NSString *)placementKey;
 */

@end
