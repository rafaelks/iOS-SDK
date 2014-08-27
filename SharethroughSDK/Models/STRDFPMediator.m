//
//  STRDFPMediator.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRDFPMediator.h"

@implementation STRDFPMediator

@synthesize delegate = delegate_;

- (void)requestBannerAd:(GADAdSize)adSize
              parameter:(NSString *)serverParameter
                  label:(NSString *)serverLabel
                request:(GADCustomEventRequest *)request {
    NSLog(@"Parameter:%@, Label:%@", serverParameter, serverLabel);
    
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
