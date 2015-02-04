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
#import "STRAdFixtures.h"
#import "STRDateProvider.h"

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
@property (nonatomic, weak) UITapGestureRecognizer *disclosureTapRecognizer;
@property (nonatomic, weak) NSTimer *adVisibleTimer;

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
    self.ad = ad;
    self.ad.placementIndex = placement.adIndex;
    self.placement = placement;
    [self prepareForNewAd:placement.adView];

    objc_setAssociatedObject(placement.adView, STRAdRendererKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (placement.adView.disclosureButton.buttonType != 2) {
        [NSException raise:@"STRDiscloseButtonType" format:@"The disclosure button provided by the STRAdView is not of type UIButtonTypeDetailDisclosure"];
    }
    UITapGestureRecognizer *disclosureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedDisclosureBtn:)];
    [placement.adView.disclosureButton addGestureRecognizer:disclosureRecognizer];
    self.disclosureTapRecognizer = disclosureRecognizer;

    self.presentingViewController = placement.presentingViewController;
    [self.beaconService fireImpressionForAd:ad adSize:placement.adView.frame.size];

    placement.adView.adTitle.text = ad.title;
    placement.adView.adSponsoredBy.text = [ad sponsoredBy];
    [self setDescriptionText:ad.adDescription onView:placement.adView];
    [self setBrandLogoFromAd:ad onView:placement.adView];
    placement.adView.adThumbnail.image = [ad displayableThumbnail];
    [placement.adView.adThumbnail addSubview:[ad platformLogoForWidth:placement.adView.adThumbnail.frame.size.width]];

    [placement.adView setNeedsLayout];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
    [placement.adView addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;

    if (self.ad.visibleImpressionTime == nil) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(checkIfAdIsVisible:)
                                               userInfo:[@{@"view": placement.adView} mutableCopy]
                                                repeats:YES];
        timer.tolerance = timer.timeInterval * 0.1;
        [self.timerRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

        self.adVisibleTimer = timer;
    }

    if ([placement.delegate respondsToSelector:@selector(adView:didFetchAdForPlacementKey:atIndex:)]) {
        [placement.delegate adView:placement.adView didFetchAdForPlacementKey:placement.placementKey atIndex:placement.adIndex];
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
        self.ad.visibleImpressionTime = [self.dateProvider now];
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

    if ([self.placement.delegate respondsToSelector:@selector(adView:userDidEngageAdForPlacementKey:)]) {
        [self.placement.delegate adView:self.placement.adView userDidEngageAdForPlacementKey:self.placement.placementKey];
    }

    STRInteractiveAdViewController *interactiveAdController = [[STRInteractiveAdViewController alloc] initWithAd:self.ad device:[UIDevice currentDevice] beaconService:self.beaconService injector:self.injector];
    interactiveAdController.delegate = self;
    [self.presentingViewController presentViewController:interactiveAdController animated:YES completion:nil];
}

- (IBAction)tappedDisclosureBtn:(id)sender
{
    STRInteractiveAdViewController *adController = [[STRInteractiveAdViewController alloc] initWithAd:(STRAdvertisement *)[STRAdFixtures privacyInformationAd]
                                                                                               device:[UIDevice currentDevice]
                                                                                        beaconService:nil
                                                                                             injector:self.injector];
    adController.delegate = self;
    [self.presentingViewController presentViewController:adController animated:YES completion:nil];
}

#pragma mark - <STRInteractiveAdViewControllerDelegate>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    if ([self.placement.delegate respondsToSelector:@selector(adView:willDismissModalForPlacementKey:)]) {
        [self.placement.delegate adView:self.placement.adView willDismissModalForPlacementKey:self.placement.placementKey];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)prepareForNewAd:(UIView<STRAdView> *)view {
    STRAdRenderer *oldRenderer = objc_getAssociatedObject(view, STRAdRendererKey);
    [oldRenderer.adVisibleTimer invalidate];
    [view removeGestureRecognizer:oldRenderer.tapRecognizer];
    [view.disclosureButton removeGestureRecognizer:oldRenderer.disclosureTapRecognizer];

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
