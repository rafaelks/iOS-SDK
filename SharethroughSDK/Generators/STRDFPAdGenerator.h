//
//  STRDFPAdGenerator.h
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRPromise.h"

#import "GADBannerViewDelegate.h"

@protocol STRAdView, STRAdViewDelegate;
@class STRAdService, STRBeaconService, STRInjector;

extern char const * const STRDFPAdGeneratorKey;

@interface STRDFPAdGenerator : NSObject<GADBannerViewDelegate>


- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService runLoop:(NSRunLoop *)timerRunLoop injector:(STRInjector *)injector;
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate;


@end
