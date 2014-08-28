//
//  STRDFPMediator.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRDFPMediator.h"

#import "STRDFPManager.h"
#import "STRPromise.h"

@implementation STRDFPMediator

@synthesize delegate = delegate_;

- (void)requestBannerAd:(GADAdSize)adSize
              parameter:(NSString *)serverParameter
                  label:(NSString *)serverLabel
                request:(GADCustomEventRequest *)request {
    NSLog(@"Parameter:%@, Label:%@", serverParameter, serverLabel);
    
    NSDictionary* extras = [request additionalParameters];
    NSLog(@"Placement Key: %@", extras[@"placementKey"]);
    
    [self.delegate customEventBanner:self didReceiveAd:[UIView new]];
    
    STRPromise *placeAdPromise = [[STRDFPManager sharedInstance] renderCreative:serverParameter inPlacement:extras[@"placementKey"]];
    [placeAdPromise then:^id(id value) {
        //[self.delegate customEventBanner:self didReceiveAd:value];
        return nil;
    } error:^id(NSError *error) {
        //[self.delegate customEventBanner:self didFailAd:error];
        return nil;
    }];
}

#pragma mark GADCustomEventBannerDelegate
/*
- (void)adViewDidReceiveAd:(MyBanner *)view {
    [self.delegate customEventBanner:self didReceiveAd:view];
}

- (void)adView:(MyBanner *)view
didFailToReceiveAdWithError:(NSError *)error {
    [self.delegate customEventBanner:self didFailAd:error];
}

- (void)adViewWillPresentScreen:(MyBanner *)adView {
    [self.delegate customEventBannerWillPresentModal:self];
}

- (void)adViewWillDismissScreen:(MyBanner *)adView {
    [self.delegate customEventBannerWillDismissModal:self];
}

- (void)adViewDidDismissScreen:(MyBanner *)adView {
    [self.delegate customEventBannerDidDismissModal:self];
}

- (void)adViewWillLeaveApplication:(MyBanner *)adView {
    [self.delegate customEventBannerWillLeaveApplication:self];
}
*/

@end
