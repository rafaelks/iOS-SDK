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
#import "STRLogging.h"

@implementation STRDFPMediator

@synthesize delegate = delegate_;

- (void)requestBannerAd:(GADAdSize)adSize
              parameter:(NSString *)serverParameter
                  label:(NSString *)serverLabel
                request:(GADCustomEventRequest *)request {
    
    NSDictionary* extras = [request additionalParameters];
    
    TLog(@"Parameter:%@, Label:%@, Placement Key: %@, DFP Path: %@", serverParameter, serverLabel, extras[@"placementKey"], extras[@"adUnitID"]);
    
    STRPromise *placeAdPromise = [[STRDFPManager sharedInstance] renderAdForParameter:serverParameter inPlacement:extras[@"adUnitID"]];
    [placeAdPromise then:^id(UIView<STRAdView>  *adView) {
        [self.delegate customEventBanner:self didReceiveAd:[UIView new]];
        return nil;
    } error:^id(NSError *error) {
        [self.delegate customEventBanner:self didFailAd:error];
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
