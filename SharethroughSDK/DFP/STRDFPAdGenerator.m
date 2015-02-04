//
//  STRDFPAdGenerator.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <objc/runtime.h>

#import "STRDFPAdGenerator.h"

#import "STRAdGenerator.h"
#import "STRAdRenderer.h"
#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRAdView.h"
#import "STRAdViewDelegate.h"
#import "STRDeferred.h"
#import "STRDFPManager.h"
#import "STRInjector.h"
#import "STRRestClient.h"

#import "GADBannerView.h"
#import "GADCustomEventExtras.h"

#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

char const * const STRDFPAdGeneratorKey = "STRDFPAdGeneratorKey";

@interface STRDFPAdGenerator ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, weak) STRInjector *injector;
@property (nonatomic, strong) STRRestClient *restClient;

@property (nonatomic, strong) NSMutableDictionary *DFPPathCache;
@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, strong) GADCustomEventExtras *extras;

@end

@implementation STRDFPAdGenerator
- (id)initWithAdService:(STRAdService *)adService
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
        self.bannerView.delegate = self;
    }
    return self;
}

- (void)placeAdInPlacement:(STRAdPlacement *)placement {
    if ([self.adService isAdCachedForPlacement:placement]) {
        //DFPDeferred is used for UITableView and UICollectionView APIs to prefetch ads
        if (placement.DFPDeferred != nil) {
            [placement.DFPDeferred resolveWithValue:nil];
        } else {
            STRPromise *adPromise = [self.adService fetchAdForPlacement:placement];
            [adPromise then:^id(STRAdvertisement *ad) {

                STRAdRenderer *renderer = [self.injector getInstance:[STRAdRenderer class]];
                [renderer renderAd:ad inPlacement:placement];

                return ad;
            } error:^id(NSError *error) {
                if (error.code != kRequestInProgress && [placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:atIndex:)]) {
                    [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey atIndex:placement.adIndex];
                }
                return error;
            }];
        }
    } else if (placement.DFPPath && [placement.DFPPath length] > 0) {
        [self initializeDFPRrequesForPlacement:placement];
    } else {
        STRPromise *DFPPathPromise = [self fetchDFPPathForPlacementKey:placement.placementKey];
        [DFPPathPromise then:^id(NSString *value) {
            if ([value length] > 0) {
                placement.DFPPath = value;
                [self initializeDFPRrequesForPlacement:placement];
            } else {
                if ([placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:atIndex:)]) {
                    [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey atIndex:placement.adIndex];
                }
            }
            return value;
        } error:^id(NSError *error) {
            if ([placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:atIndex:)]) {
                [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey atIndex:placement.adIndex];
            }
            return error;
        }];
    }
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
            [self.DFPPathCache setObject:value forKey:placementKey];
            [deferred resolveWithValue:value];
            return value;
        } error:^id(NSError *error) {
            [deferred rejectWithError:error];
            return error;
        }];
    }
    return deferred.promise;
}

- (void)initializeDFPRrequesForPlacement:(STRAdPlacement *)placement {
    self.bannerView.adUnitID = placement.DFPPath;
    self.bannerView.rootViewController = placement.presentingViewController;

    [placement.adView addSubview:self.bannerView];

    [self.extras setExtras:@{@"placementKey": placement.placementKey, @"adUnitID": placement.DFPPath} forLabel:@"Sharethrough"];

    GADRequest *request = [GADRequest request];
    [request registerAdNetworkExtras:self.extras];
    [self.bannerView loadRequest:request];

    [[STRDFPManager sharedInstance] cacheAdPlacement:placement];
}

#pragma mark GAdBannerViewDelegate
- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    [[STRDFPManager sharedInstance] updateDelegateWithNoAdShownforPlacement:view.adUnitID];
}

@end
