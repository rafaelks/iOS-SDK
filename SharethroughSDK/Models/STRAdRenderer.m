//
//  STRAdRenderer.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdRenderer.h"

#import <objc/runtime.h>

#import "STRAdPlacement.h"
#import "STRAdView.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import "STRNetworkClient.h"
#import "STRAdViewDelegate.h"
#import "STRPromise.h"
#import "STRDateProvider.h"
#import "UIView+Visible.h"
#import "STRLogging.h"
#import "STRViewTracker.h"

char const * const STRAdRendererKey = "STRAdRendererKey";

@interface STRAdRenderer ()<STRInteractiveAdViewControllerDelegate>

@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, strong) STRDateProvider *dateProvider;
@property (nonatomic, weak) NSRunLoop *timerRunLoop;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, weak) STRInjector *injector;

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, strong) STRAdPlacement *placement;
@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;

@end

@implementation STRAdRenderer

- (id)initWithBeaconService:(STRBeaconService *)beaconService
               dateProvider:(STRDateProvider *)dateProvider
                    runLoop:(NSRunLoop *)timerRunLoop
              networkClient:(STRNetworkClient *)networkClient
                   injector:(STRInjector *)injector;
{
    self = [super init];
    if (self) {
        self.beaconService = beaconService;
        self.dateProvider = dateProvider;
        self.timerRunLoop = timerRunLoop;
        self.networkClient = networkClient;
        self.injector = injector;
    }
    return self;
}

- (void)renderAd:(STRAdvertisement *)ad inPlacement:(STRAdPlacement *)placement {
    TLog(@"pkey:%@ ckey:%@ presentingViewController:%p",placement.placementKey, ad.creativeKey, placement.presentingViewController);
    self.ad = ad;
    self.ad.placementIndex = placement.adIndex;
    self.placement = placement;
    [self prepareForNewAd:placement.adView];

    objc_setAssociatedObject(placement.adView, STRAdRendererKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (placement.adView.disclosureButton.buttonType != 2) {
        [NSException raise:@"STRDiscloseButtonType" format:@"The disclosure button provided by the STRAdView is not of type UIButtonTypeDetailDisclosure"];
    }


    self.presentingViewController = placement.presentingViewController;
    if ([self.beaconService fireImpressionForAd:ad adSize:placement.adView.frame.size]) {
        [self.beaconService fireThirdPartyBeacons:ad.thirdPartyBeaconsForImpression forPlacementWithStatus:ad.placementStatus];
    }

    placement.adView.adTitle.text = ad.title;
    placement.adView.adSponsoredBy.text = [ad sponsoredBy];
    [self setDescriptionText:ad.adDescription onView:placement.adView];
    [self setBrandLogoFromAd:ad onView:placement.adView];
    [ad setThumbnailImageInView:placement.adView.adThumbnail];
    [placement.adView.adThumbnail addSubview:[ad platformLogoForWidth:placement.adView.adThumbnail.frame.size.width]];

    [placement.adView setNeedsLayout];

    STRViewTracker *viewTracker = [[STRViewTracker alloc] initWithInjector:self.injector];
    [viewTracker trackAd:ad inView:placement.adView withViewContorller:placement.presentingViewController];
    [viewTracker addDiclosureTapRecognizerToView:placement.adView.disclosureButton];

    if ([placement.delegate respondsToSelector:@selector(adView:didFetchAd:ForPlacementKey:atIndex:)]) {
        [placement.delegate adView:placement.adView didFetchAd:ad ForPlacementKey:placement.placementKey atIndex:placement.adIndex];
    }
}

#pragma mark - <STRInteractiveAdViewControllerDelegate>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    TLog(@"pkey:%@ ckey:%@",self.placement.placementKey, self.ad.creativeKey);
    if ([self.placement.delegate respondsToSelector:@selector(adView:willDismissModalForPlacementKey:)]) {
        [self.placement.delegate adView:self.placement.adView willDismissModalForPlacementKey:self.placement.placementKey];
    }
}

#pragma mark - Private

- (void)prepareForNewAd:(UIView<STRAdView> *)view {
    [STRViewTracker unregisterView:view];

    [self clearTextFromView:view];
}

- (void)clearTextFromView:(UIView<STRAdView> *)view {
    view.adTitle.text = @"";
    view.adSponsoredBy.text = @"";
    view.adThumbnail.image = nil;
    for (UIView *subView in view.adThumbnail.subviews)
    {
        [subView removeFromSuperview];
    }
    [self setDescriptionText:@"" onView:view];
    if ([view respondsToSelector:@selector(adBrandLogo)]) {
        view.adBrandLogo.image = nil;
    }
}

- (void)setDescriptionText:(NSString *)text onView:(UIView<STRAdView> *)view {
    if ([view respondsToSelector:@selector(adDescription)]) {
        view.adDescription.text = text;
    }
}

- (void)setBrandLogoFromAd:(STRAdvertisement *)ad onView:(UIView<STRAdView> *)view {
    if ([view respondsToSelector:@selector(adBrandLogo)] && ad.brandLogoURL != nil) {

        if (ad.brandLogoImage != nil) {
            view.adBrandLogo.image = ad.brandLogoImage;
        } else {
            NSURLRequest *brandLogoRequest = [NSURLRequest requestWithURL:ad.brandLogoURL];
            [[self.networkClient get:brandLogoRequest] then:^id(NSData *data) {
                ad.brandLogoImage = [UIImage imageWithData:data];
                view.adBrandLogo.image = ad.brandLogoImage;
                return data;
            } error:^id(NSError *error) {
                return error;
            }];
        }
    }
}

@end
