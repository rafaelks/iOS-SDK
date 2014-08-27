//
//  STRDFPAdGenerator.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <objc/runtime.h>

#import "STRDFPAdGenerator.h"

#import "STRAdView.h"
#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRDeferred.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import "STRAdViewDelegate.h"

#import "GADBannerView.h"

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

char const * const STRDFPAdGeneratorKey = "STRDFPAdGeneratorKey";

@interface STRDFPAdGenerator ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, weak) STRInjector *injector;
@property (nonatomic, strong) NSMutableDictionary *DFPPathCache;

@end

@implementation STRDFPAdGenerator
- (id)initWithAdService:(STRAdService *)adService
          beaconService:(STRBeaconService *)beaconService
                runLoop:(NSRunLoop *)timerRunLoop
               injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.adService = adService;
        self.injector = injector;
        self.DFPPathCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {
    
    STRPromise *DFPPathPromise = [self fetchDFPPathForPlacementKey:placementKey];
    [DFPPathPromise then:^id(id value) {
        ALog(@"%@", (NSString *)value);

        GADBannerView *bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
        bannerView.adUnitID = @"/11935007/Test-Tags/Custom-Event-Test"; //value;
        bannerView.rootViewController = presentingViewController;
        
        [view addSubview:bannerView];
        
        [bannerView loadRequest:[GADRequest request]];
        
        return value;
    } error:^id(NSError *error) {
        //TODO: Handle Error case
        return error;
    }];
}

#pragma mark GADBannerViewDelegate
#pragma mark Ad Request Lifecycle Notifications

- (void)adViewDidReceiveAd:(GADBannerView *)view {
    ALog(@"");
}

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    ALog(@"");
}

#pragma mark Click-Time Lifecycle Notifications

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    ALog(@"");
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    ALog(@"");
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    ALog(@"");
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    ALog(@"");
}

#pragma mark private

- (STRPromise *)fetchDFPPathForPlacementKey:(NSString *)placementKey {
    STRDeferred *deferred = [STRDeferred defer];
    
    NSString *DFPPath = self.DFPPathCache[placementKey];
    if (DFPPath) {
        [deferred resolveWithValue:DFPPath];
    } else {
        //TODO:     Fetch from Bakery
        [deferred resolveWithValue:@"/11935007/Test-Tags/Custom-Event-Test"];
    }
    return deferred.promise;
}

@end
