//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRAdView, STRAdViewDelegate;
@class STRAdService, STRBeaconService, STRInjector;

extern char const * const STRAdGeneratorKey;

@interface STRAdGenerator : NSObject

- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService runLoop:(NSRunLoop *)timerRunLoop injector:(STRInjector *)injector;
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate;

@end
