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
#import "STRDFPManager.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import "STRAdViewDelegate.h"
#import "STRRestClient.h"


#import "GADBannerView.h"
#import "GADCustomEventExtras.h"

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

char const * const STRDFPAdGeneratorKey = "STRDFPAdGeneratorKey";

@interface STRDFPAdGenerator ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, weak) STRInjector *injector;
@property (nonatomic, strong) STRRestClient *restClient;

@property (nonatomic, strong) NSMutableDictionary *DFPPathCache;
@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, strong) GADCustomEventExtras *extras;

@end

@implementation STRDFPAdGenerator
- (id)initWithAdService:(STRAdService *)adService
          beaconService:(STRBeaconService *)beaconService
                runLoop:(NSRunLoop *)timerRunLoop
               injector:(STRInjector *)injector
             restClient:(STRRestClient *)restClient {
    self = [super init];
    if (self) {
        self.adService = adService;
        self.injector = injector;
        self.restClient = restClient;
        self.DFPPathCache = [NSMutableDictionary dictionary];
        self.bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
        self.extras = [[GADCustomEventExtras alloc] init];
    }
    return self;
}

- (void)placeAdInPlacement:(STRAdPlacement *)placement {

    if ([self.adService isAdCachedForPlacementKey:placement.placementKey]) {
        
    } else {
        STRPromise *DFPPathPromise = [self fetchDFPPathForPlacementKey:placement.placementKey];
        [DFPPathPromise then:^id(id value) {
            ALog(@"Value: %@",value);
            
            self.bannerView.adUnitID = value;
            self.bannerView.rootViewController = placement.presentingViewController;
            
            [placement.adView addSubview:self.bannerView];
            
            [self.extras setExtras:@{@"placementKey": placement.placementKey} forLabel:@"Sharethrough"];
            
            GADRequest *request = [GADRequest request];
            [request registerAdNetworkExtras:self.extras];
            [self.bannerView loadRequest:request];
            
            [[STRDFPManager sharedInstance] cacheAdPlacement:placement];
            
            return value;
        } error:^id(NSError *error) {
            //TODO: Handle Error case
            return error;
        }];
    }
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
        STRPromise *DFPPathPromise = [self.restClient getDFPPathForPlacement:placementKey];
        [DFPPathPromise then:^id(id value) {
            ALog(@"Value: %@", value);
            [self.DFPPathCache setObject:value forKey:placementKey];
            [deferred resolveWithValue:value];
            return value;
        } error:^id(NSError *error) {
            [deferred rejectWithError:error];
            return error;
        }];
        //[deferred resolveWithValue:@"/11935007/Test-Tags/Custom-Event-Test"];
    }
    return deferred.promise;
}

@end
