//
//  STRViewTracker.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 6/4/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import <objc/runtime.h>
#import "STRViewTracker.h"

#import "STRAdvertisement.h"
#import "STRAdInstantHostedVideo.h"
#import "STRAdvertisementDelegate.h"
#import "STRBeaconService.h"
#import "STRDateProvider.h"
#import "STRInjector.h"
#import "STRInteractiveAdViewController.h"
#import "STRLogging.h"
#import "UIView+Visible.h"
#import "STRAdFixtures.h"
#import "STRAdView.h"

char const * const STRViewTrackerKey = "STRViewTrackerKey";

@interface STRViewTracker ()

@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, strong) STRDateProvider *dateProvider;
@property (nonatomic, weak) NSRunLoop *timerRunLoop;
@property (nonatomic, weak) STRInjector *injector;

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, weak) UITapGestureRecognizer *disclosureTapRecognizer;
@property (nonatomic, weak) NSTimer *adVisibleTimer;
@end

@implementation STRViewTracker

- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
        self.beaconService = [self.injector getInstance:[STRBeaconService class]];
        self.dateProvider = [self.injector getInstance:[STRDateProvider class]];
        self.timerRunLoop = [self.injector getInstance:[NSRunLoop class]];
    }
    return self;
}

- (void)trackAd:(STRAdvertisement *)ad inView:(UIView *)view withViewContorller:(UIViewController *)viewController {
    TLog(@"Ad: %@ View: %@ ViewController: %p", ad, view, viewController);

    objc_setAssociatedObject(view, STRViewTrackerKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    self.ad = ad;
    self.presentingViewController = viewController;

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
    [view addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;

    if (self.ad.visibleImpressionTime == nil) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1
                                                 target:self
                                               selector:@selector(checkIfAdIsVisible:)
                                               userInfo:[@{@"view": view} mutableCopy]
                                                repeats:YES];
        timer.tolerance = timer.timeInterval * 0.1;
        [self.timerRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

        self.adVisibleTimer = timer;
    } else {
        [self setUpSimpleVisibilityCheckerInView:view];
    }
}

+ (void)unregisterView:(UIView *)view {
    STRViewTracker *oldTracker = objc_getAssociatedObject(view, STRViewTrackerKey);
    if (oldTracker) {
        [oldTracker.adVisibleTimer invalidate];
        [view removeGestureRecognizer:oldTracker.tapRecognizer];

        UIView <STRAdView>*adView = (UIView <STRAdView>*)view;
        if ([adView respondsToSelector:@selector(disclosureButton)]) {
            [adView.disclosureButton removeGestureRecognizer:oldTracker.disclosureTapRecognizer];
        }
    }
    objc_removeAssociatedObjects(view);
}

- (void)addDiclosureTapRecognizerToView:(UIView *)view {
    UITapGestureRecognizer *disclosureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedDisclosureBtn:)];
    view.userInteractionEnabled = YES;
    [view addGestureRecognizer:disclosureRecognizer];
    self.disclosureTapRecognizer = disclosureRecognizer;
}

#pragma mark - Private

- (void)checkIfAdIsVisible:(NSTimer *)timer {
    UIView *view = timer.userInfo[@"view"];

    if (!view.superview) {
        NSLog(@"Warning: The ad view is not in a super view. No visibility tracking will occur.");
        [timer invalidate];
        return;
    }

    CGFloat percentVisible = [view percentVisible];

    CGFloat secondsVisible = [timer.userInfo[@"secondsVisible"] floatValue];

    if (percentVisible >= 0.5 && secondsVisible < 1.0) {
        timer.userInfo[@"secondsVisible"] = @(secondsVisible + timer.timeInterval);
    } else if (percentVisible >= 0.5 && secondsVisible >= 1.0) {
        if ([self.beaconService fireVisibleImpressionForAd:self.ad adSize:view.frame.size]) {
            [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForVisibility  forPlacementWithStatus:self.ad.placementStatus];
        }

        if ([self.ad.delegate respondsToSelector:@selector(adWillLogImpression:)]) {
            [self.ad.delegate adWillLogImpression:self.ad];
        }
        self.ad.visibleImpressionTime = [self.dateProvider now];
        [self.ad adVisibleInView:view];
        [timer invalidate];
        [self setUpSimpleVisibilityCheckerInView:view];
    } else {
        [self.ad adNotVisibleInView:view];
        [timer.userInfo removeObjectForKey:@"secondsVisible"];
    }
}

- (void)setUpSimpleVisibilityCheckerInView:(UIView *)view {
    TLog(@"");
    if ([self.ad isKindOfClass:[STRAdInstantHostedVideo class]]) {
        STRAdInstantHostedVideo *hostedAd = (STRAdInstantHostedVideo *)self.ad;
        if (hostedAd.beforeEngagement) {
            [self.adVisibleTimer invalidate];
            NSTimer *timer = [NSTimer timerWithTimeInterval:0.5
                                                     target:self
                                                   selector:@selector(simpleCheckIfAdVisible:)
                                                   userInfo:[@{@"view": view} mutableCopy]
                                                    repeats:YES];
            timer.tolerance = timer.timeInterval * 0.5;
            [self.timerRunLoop addTimer:timer forMode:NSRunLoopCommonModes];

            self.adVisibleTimer = timer;
        }
    }
}

- (void)simpleCheckIfAdVisible:(NSTimer *)timer {
    UIView *view = timer.userInfo[@"view"];
    CGFloat percentVisible = [view percentVisible];
    if (percentVisible >= 0.5) {
        if (![self.ad adVisibleInView:view]) {
            [timer invalidate];
        }
    } else {
        if (![self.ad adNotVisibleInView:view]) {
            [timer invalidate];
        }
    }
}

- (void)tappedAd:(UITapGestureRecognizer *)tapRecognizer {
    TLog(@"pkey:%@ ckey:%@",self.ad.placementKey, self.ad.creativeKey);
    UIView *view = tapRecognizer.view;
    if ([self.ad.action isEqualToString:STRYouTubeAd] ||
        [self.ad.action isEqualToString:STRHostedVideoAd] ||
        [self.ad.action isEqualToString:STRVineAd])
    {
        [self.beaconService fireVideoPlayEvent:self.ad adSize:view.frame.size];
    } else {
        [self.beaconService fireClickForAd:self.ad adSize:view.frame.size];
    }
    [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForPlay  forPlacementWithStatus:self.ad.placementStatus];
    [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForClick  forPlacementWithStatus:self.ad.placementStatus];
    if ([self.ad.delegate respondsToSelector:@selector(adDidClick:)]) {
        TLog(@"Delegate responds to selector %@", NSStringFromSelector(@selector(adDidClick:)));
        [self.ad.delegate adDidClick:self.ad];
    }
    UIViewController *engagementViewController = [self.ad viewControllerForPresentingOnTap];
    TLog(@"PresentingViewController: %p, ViewController to Present: %p", self.presentingViewController, engagementViewController);
    [self.presentingViewController presentViewController:engagementViewController animated:YES completion:nil];
}

- (IBAction)tappedDisclosureBtn:(id)sender
{
    TLog(@"pkey:%@ ckey:%@",self.ad.placementKey, self.ad.creativeKey);
    STRInteractiveAdViewController *adController = [[STRInteractiveAdViewController alloc] initWithAd:(STRAdvertisement *)[STRAdFixtures privacyInformationAd]
                                                                                               device:[UIDevice currentDevice]
                                                                                          application:[UIApplication sharedApplication]
                                                                                        beaconService:self.beaconService
                                                                                             injector:self.injector];
    [self.presentingViewController presentViewController:adController animated:YES completion:nil];
}
@end
