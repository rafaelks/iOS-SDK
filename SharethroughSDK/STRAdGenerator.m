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
#import "STRBundleSettings.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>

char const * const kAdGeneratorKey = "kAdGeneratorKey";

@interface STRAdGenerator ()<STRInteractiveAdViewControllerDelegate>

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIView *spinner;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;

@end

@implementation STRAdGenerator

- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService {
    self = [super init];
    if (self) {
        self.adService = adService;
        self.beaconService = beaconService;
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController {
    STRAdGenerator *oldGenerator = objc_getAssociatedObject(view, kAdGeneratorKey);
    [view removeGestureRecognizer:oldGenerator.tapRecognizer];

    objc_setAssociatedObject(view, kAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.presentingViewController = presentingViewController;

    [self addSpinnerToView:view];
    [self clearTextFromView:view];

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placementKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        [self.spinner removeFromSuperview];

        self.ad = ad;
        view.adTitle.text = ad.title;
        view.adSponsoredBy.text = [ad sponsoredBy];
        [self setDescriptionText:ad.adDescription onView:view];
        view.adThumbnail.image = [ad thumbnailWithPlayImage];

        [view setNeedsLayout];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
        [view addGestureRecognizer:tapRecognizer];
        self.tapRecognizer = tapRecognizer;

        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(checkIfAdIsVisible:)
                                               userInfo:@{@"view": view, @"placementKey": placementKey}
                                                repeats:YES];
        timer.tolerance = timer.timeInterval * 0.1;

        // spec timer saves the input parameters and returns a nil timer.
        if (timer) {
            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
        }

        return ad;
    } error:^id(NSError *error) {
        [self.spinner removeFromSuperview];
        return error;
    }];

    [self.beaconService fireImpressionRequestForPlacementKey:placementKey];
}

- (void)checkIfAdIsVisible:(NSTimer *)timer {
    UIView *view = timer.userInfo[@"view"];
    CGRect viewFrame = [view convertRect:view.bounds toView:nil];

    if (!view.superview) {
        [timer invalidate];
        return;
    }

    if (CGRectIntersectsRect(viewFrame, view.window.frame)) {
        [self.beaconService fireVisibleImpressionForPlacementKey:timer.userInfo[@"placementKey"]];
        [timer invalidate];
    }
}

- (void)tappedAd:(UITapGestureRecognizer *)tapRecognizer {
    STRInteractiveAdViewController *interactiveAdController = [[STRInteractiveAdViewController alloc] initWithAd:self.ad device:[UIDevice currentDevice]];
    interactiveAdController.delegate = self;
    [self.presentingViewController presentViewController:interactiveAdController animated:YES completion:nil];
}

#pragma mark - <STRInteractiveAdViewControllerDelegate>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

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

