//
//  STRAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdGenerator.h"
#import "STRAdView.h"
#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "STRAdViewDelegate.h"
#import "STRAdRenderer.h"
#import "STRAdPlacement.h"
#import "STRInjector.h"

char const * const STRAdGeneratorKey = "STRAdGeneratorKey";

@interface STRAdGenerator ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, weak) UIView *spinner;
@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, weak) NSRunLoop *timerRunLoop;
@property (nonatomic, weak) NSTimer *adVisibleTimer;
@property (nonatomic, weak) STRInjector *injector;

@end

@implementation STRAdGenerator

- (id)initWithAdService:(STRAdService *)adService
          beaconService:(STRBeaconService *)beaconService
                runLoop:(NSRunLoop *)timerRunLoop
               injector:(STRInjector *)injector
{
    self = [super init];
    if (self) {
        self.adService = adService;
        self.beaconService = beaconService;
        self.timerRunLoop = timerRunLoop;
        self.injector = injector;
    }
    return self;
}

- (void)placeAdInPlacement:(STRAdPlacement *)placement {
    [self addSpinnerToView:placement.adView];

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placement.placementKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        [self.spinner removeFromSuperview];

        STRAdRenderer *renderer = [self.injector getInstance:[STRAdRenderer class]];
        [renderer renderAd:ad inPlacement:placement];

        return ad;
    } error:^id(NSError *error) {
        [self.spinner removeFromSuperview];
        [placement.adView setNeedsLayout];

        if ([placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:)]) {
            [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey];
        }
        return error;
    }];
}

- (STRPromise *)prefetchAdForPlacementKey:(NSString *)placementKey {
    return [self.adService fetchAdForPlacementKey:placementKey];
}

- (void)addSpinnerToView:(UIView *)view {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:spinner];
    [spinner startAnimating];
    [self centerView:spinner toView:view];
    self.spinner = spinner;
}

- (void)centerView:(UIView *)viewToCenter toView:(UIView *)referenceView {
    [referenceView addConstraint:[NSLayoutConstraint constraintWithItem:viewToCenter
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:referenceView
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0
                                                               constant:0]];
    [referenceView addConstraint:[NSLayoutConstraint constraintWithItem:viewToCenter
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:referenceView
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1.0
                                                               constant:0]];
}

@end

