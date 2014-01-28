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

@interface STRAdGenerator ()<STRInteractiveAdViewControllerDelegate>

@property (nonatomic, weak) STRAdService *adService;
@property (nonatomic, weak) STRBeaconService *beaconService;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, weak) UIView *spinner;
@property (nonatomic, strong) STRAdvertisement *ad;

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
        view.adThumbnail.image = ad.thumbnailImage;
        [self addPlayButtonToView:view];

        [view setNeedsLayout];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
        [view addGestureRecognizer:tapRecognizer];

        return ad;
    } error:^id(NSError *error) {
        [self.spinner removeFromSuperview];
        return error;
    }];

    [self.beaconService fireImpressionRequestForPlacementKey:placementKey];
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

- (void)addPlayButtonToView:(UIView<STRAdView> *)view {
    NSString *imagePath = [[STRBundleSettings bundleForResources] pathForResource:@"play-btn@2x.png" ofType:nil];

    UIImageView *playButtonView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
    playButtonView.translatesAutoresizingMaskIntoConstraints = NO;
    [view.adThumbnail addSubview:playButtonView];
    [self centerView:playButtonView toView:view.adThumbnail];
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

