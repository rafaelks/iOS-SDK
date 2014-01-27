//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRAdView;
@class STRAdService;

@interface STRAdGenerator : NSObject

- (id)initWithAdService:(STRAdService *)adService;
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController;

@end
