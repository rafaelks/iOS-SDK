//
//  STRFakeAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRFakeAdGenerator.h"
#import <objc/runtime.h>
#import "STRAdView.h"

@implementation STRFakeAdGenerator

- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService runLoop:(NSRunLoop *)timerRunLoop injector:(STRInjector *)injector {

    [NSException raise:@"STRFakeAdGeneratorError"
                format:@"Fake ad generator does not respond to %@, because it does not use any of these things.", NSStringFromSelector(_cmd)];
    return nil;
}
- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {

    objc_setAssociatedObject(view, STRAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    view.adTitle.text = @"Generic Ad Title";
    view.adSponsoredBy.text = @"Promoted by Sharethrough";
}

@end
