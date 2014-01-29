//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRAdView;
@class STRAdService, STRBeaconService;

extern char const * const kAdGeneratorKey;

@interface STRAdGenerator : NSObject

- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService;
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController;

@end
