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
#import "STRPromise.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "STRAdViewDelegate.h"

char const * const STRAdGeneratorKey = "STRAdGeneratorKey";

@interface STRAdGenerator ()<STRInteractiveAdViewControllerDelegate>

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIView *spinner;
@property (nonatomic, strong) STRAdvertisement *ad;
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

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate {
    [self prepareForNewAd:view];

    objc_setAssociatedObject(view, STRAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.presentingViewController = presentingViewController;
    [self addSpinnerToView:view];

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placementKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        [self.beaconService fireImpressionForAd:ad adSize:view.frame.size];

        [self.spinner removeFromSuperview];

        self.ad = ad;
        view.adTitle.text = ad.title;
        view.adSponsoredBy.text = [ad sponsoredBy];
        [self setDescriptionText:ad.adDescription onView:view];
        view.adThumbnail.image = [ad displayableThumbnail];

        [view setNeedsLayout];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
        [view addGestureRecognizer:tapRecognizer];
        self.tapRecognizer = tapRecognizer;

        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(checkIfAdIsVisible:)
                                               userInfo:[@{@"view": view} mutableCopy]
                                                repeats:YES];
        timer.tolerance = timer.timeInterval * 0.1;
        [self.timerRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

        self.adVisibleTimer = timer;

        if ([delegate respondsToSelector:@selector(adView:didFetchAdForPlacementKey:)]) {
            [delegate adView:view didFetchAdForPlacementKey:placementKey];
        }

        return ad;
    } error:^id(NSError *error) {
        [self.spinner removeFromSuperview];

        if ([delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:)]) {
            [delegate adView:view didFailToFetchAdForPlacementKey:placementKey];
            [view setNeedsLayout];
        }
        return error;
    }];
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
    if ([self.ad.action isEqualToString:STRClickoutAd]) {
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
    STRAdGenerator *oldGenerator = objc_getAssociatedObject(view, STRAdGeneratorKey);
    [oldGenerator.adVisibleTimer invalidate];
    [view removeGestureRecognizer:oldGenerator.tapRecognizer];

    [self clearTextFromView:view];
}

- (void)setDescriptionText:(NSString *)text onView:(UIView<STRAdView> *)view {
    if ([view respondsToSelector:@selector(adDescription)]) {
        view.adDescription.text = text;
    }
}

- (void)addSpinnerToView:(UIView *)view {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:spinner];
    [spinner startAnimating];
    [self centerView:spinner toView:view];
    self.spinner = spinner;
}

- (void)clearTextFromView:(UIView<STRAdView> *)view {
    view.adTitle.text = @"";
    view.adSponsoredBy.text = @"";
    [self setDescriptionText:@"" onView:view];
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

