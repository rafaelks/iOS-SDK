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
#import "STRAdvertisementDelegate.h"
#import "STRBeaconService.h"
#import "STRDateProvider.h"
#import "STRInjector.h"
#import "STRInteractiveAdViewController.h"
#import "STRLogging.h"
#import "UIView+Visible.h"

char const * const STRViewTrackerKey = "STRViewTrackerKey";

@interface STRViewTracker ()<STRInteractiveAdViewControllerDelegate>

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
    }
}

+ (void)unregisterView:(UIView *)view {
    STRViewTracker *oldTracker = objc_getAssociatedObject(view, STRViewTrackerKey);
    if (oldTracker) {
        [oldTracker.adVisibleTimer invalidate];
        [view removeGestureRecognizer:oldTracker.tapRecognizer];
    }
    objc_removeAssociatedObjects(view);
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
        [self.beaconService fireVisibleImpressionForAd:self.ad
                                                adSize:view.frame.size];
        [self.beaconService fireThirdPartyBeacons:self.ad.thirdPartyBeaconsForVisibility  forPlacementWithStatus:self.ad.placementStatus];
        if ([self.ad.delegate respondsToSelector:@selector(adWillLogImpression:)]) {
            [self.ad.delegate adWillLogImpression:self.ad];
        }
        self.ad.visibleImpressionTime = [self.dateProvider now];
        [timer invalidate];
    } else {
        [timer.userInfo removeObjectForKey:@"secondsVisible"];
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
        [self.ad.delegate adDidClick:self.ad];
    }
    STRInteractiveAdViewController *interactiveAdController = [[STRInteractiveAdViewController alloc] initWithAd:self.ad
                                                                                                          device:[UIDevice currentDevice]
                                                                                                     application:[UIApplication sharedApplication]
                                                                                                   beaconService:self.beaconService
                                                                                                        injector:self.injector];
    interactiveAdController.delegate = self;
    [self.presentingViewController presentViewController:interactiveAdController animated:YES completion:nil];
}

#pragma mark - <STRInteractiveAdViewControllerDelegate>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    TLog(@"pkey:%@ ckey:%@",self.ad.placementKey, self.ad.creativeKey);
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
@end