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

@interface STRAdGenerator ()<STRInteractiveAdViewControllerDelegate>

@property (nonatomic, weak) STRAdService *adService;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) STRAdvertisement *ad;

@end

@implementation STRAdGenerator

- (id)initWithAdService:(STRAdService *)adService {
    self = [super init];
    if (self) {
        self.adService = adService;
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController {
    self.presentingViewController = presentingViewController;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:spinner];
    [spinner startAnimating];
    [self centerView:spinner toView:view];

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placementKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        [spinner removeFromSuperview];

        self.ad = ad;
        view.adTitle.text = ad.title;
        view.adSponsoredBy.text = [ad sponsoredBy];
        view.adThumbnail.image = ad.thumbnailImage;
        [self addPlayButtonToView:view];

        if ([view respondsToSelector:@selector(adDescription)]) {
            view.adDescription.text = ad.adDescription;
        }
        [view setNeedsLayout];

        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
        [view addGestureRecognizer:tapRecognizer];

        return ad;
    } error:^id(NSError *error) {
        [spinner removeFromSuperview];
        return error;
    }];
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

- (void)tappedAd:(UITapGestureRecognizer *)tapRecognizer {
    STRInteractiveAdViewController *interactiveAdController = [[STRInteractiveAdViewController alloc] initWithAd:self.ad device:[UIDevice currentDevice]];
    interactiveAdController.delegate = self;
    [self.presentingViewController presentViewController:interactiveAdController animated:YES completion:nil];
}

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

