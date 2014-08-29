//
//  STRAdRenderer.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdRenderer.h"

#import "STRAdPlacement.h"
#import "STRAdView.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "STRAdViewDelegate.h"

char const * const STRAdRendererKey = "STRAdRendererKey";

@interface STRAdRenderer ()<STRInteractiveAdViewControllerDelegate>

@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, weak) NSRunLoop *timerRunLoop;
@property (nonatomic, weak) STRInjector *injector;

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, weak) NSTimer *adVisibleTimer;

@end

@implementation STRAdRenderer

- (id)initWithBeaconService:(STRBeaconService *)beaconService
                    runLoop:(NSRunLoop *)timerRunLoop
                   injector:(STRInjector *)injector;
{
    self = [super init];
    if (self) {
        self.beaconService = beaconService;
        self.timerRunLoop = timerRunLoop;
        self.injector = injector;
    }
    return self;
}

- (void)renderAd:(STRAdvertisement *)ad inPlacement:(STRAdPlacement *)placement {
    self.ad = ad;

    objc_setAssociatedObject(placement.adView, STRAdRendererKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    self.presentingViewController = placement.presentingViewController;
    [self.beaconService fireImpressionForAd:ad adSize:placement.adView.frame.size];

    placement.adView.adTitle.text = ad.title;
    placement.adView.adSponsoredBy.text = [ad sponsoredBy];
    [self setDescriptionText:ad.adDescription onView:placement.adView];
    placement.adView.adThumbnail.image = [ad displayableThumbnail];

    [placement.adView setNeedsLayout];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
    [placement.adView addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;

    NSTimer *timer = [NSTimer timerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(checkIfAdIsVisible:)
                                           userInfo:[@{@"view": placement.adView} mutableCopy]
                                            repeats:YES];
    timer.tolerance = timer.timeInterval * 0.1;
    [self.timerRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

    self.adVisibleTimer = timer;

    if ([placement.delegate respondsToSelector:@selector(adView:didFetchAdForPlacementKey:)]) {
        [placement.delegate adView:placement.adView didFetchAdForPlacementKey:@""];
    }
}

- (void)checkIfAdIsVisible:(NSTimer *)timer {
    UIView *view = timer.userInfo[@"view"];
    CGRect viewFrame = [view convertRect:view.bounds toView:nil];

    if (!view.superview) {
        [timer invalidate];
        return;
    }

    CGRect intersection = CGRectIntersection(viewFrame, view.window.frame);

    CGFloat intersectionArea = intersection.size.width * intersection.size.height;
    CGFloat viewArea = view.frame.size.width * view.frame.size.height;
    CGFloat percentVisible = intersectionArea/viewArea;

    CGFloat secondsVisible = [timer.userInfo[@"secondsVisible"] floatValue];

    if (percentVisible >= 0.5 && secondsVisible < 1.0) {
        timer.userInfo[@"secondsVisible"] = @(secondsVisible + timer.timeInterval);
    } else if (percentVisible >= 0.5 && secondsVisible >= 1.0) {
        [self.beaconService fireVisibleImpressionForAd:self.ad
                                                adSize:view.frame.size];
        [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForVisibility];
        [timer invalidate];
    } else {
        [timer.userInfo removeObjectForKey:@"secondsVisible"];
    }
}

- (void)tappedAd:(UITapGestureRecognizer *)tapRecognizer {
    UIView *view = tapRecognizer.view;
    if ([self.ad.action isEqualToString:STRClickoutAd] ||
        [self.ad.action isEqualToString:STRInstagramAd] ||
        [self.ad.action isEqualToString:STRPinterestAd]) {

        [self.beaconService fireClickForAd:self.ad adSize:view.frame.size];
    } else {
        [self.beaconService fireVideoPlayEvent:self.ad adSize:view.frame.size];
    }
    [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForPlay];
    [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForClick];

    STRInteractiveAdViewController *interactiveAdController = [[STRInteractiveAdViewController alloc] initWithAd:self.ad device:[UIDevice currentDevice] beaconService:self.beaconService injector:self.injector];
    interactiveAdController.delegate = self;
    [self.presentingViewController presentViewController:interactiveAdController animated:YES completion:nil];
}

#pragma mark - <STRInteractiveAdViewControllerDelegate>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)prepareForNewAd:(UIView<STRAdView> *)view {
    STRAdRenderer *oldRenderer = objc_getAssociatedObject(view, STRAdRendererKey);
    [oldRenderer.adVisibleTimer invalidate];
    [view removeGestureRecognizer:oldRenderer.tapRecognizer];

    [self clearTextFromView:view];
}

- (void)clearTextFromView:(UIView<STRAdView> *)view {
    view.adTitle.text = @"";
    view.adSponsoredBy.text = @"";
    [self setDescriptionText:@"" onView:view];
}

- (void)setDescriptionText:(NSString *)text onView:(UIView<STRAdView> *)view {
    if ([view respondsToSelector:@selector(adDescription)]) {
        view.adDescription.text = text;
    }
}

@end
