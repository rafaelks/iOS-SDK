//
//  SharethroughSDK.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "SharethroughSDK.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRAdPlacement.h"
#import "STRGridlikeViewAdGenerator.h"
#import "STRGridlikeViewDataSourceProxy.h"
#import "STRFakeAdGenerator.h"
#import "STRBeaconService.h"
#import "STRAdService.h"
#import "STRAdCache.h"
#import "STRTestSafeModule.h"
#import "STRAdViewDelegate.h"
#import "STRLogging.h"

@interface SharethroughSDK ()

@property (nonatomic, strong) STRInjector *injector;

@end

@implementation SharethroughSDK

+ (instancetype)sharedInstance {
    __strong static SharethroughSDK *sharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
        sharedObject.injector = [STRInjector injectorForModule:[STRAppModule new]];
        TLog(@"WARNING: This version of the SDK was built with trace logging for debugging and integration purposes and should not be used in production.");
    });

    return sharedObject;
}

+ (instancetype)sharedTestSafeInstanceWithAdType:(STRFakeAdType)adType {
    __strong static SharethroughSDK *testSafeSharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        testSafeSharedObject = [[self alloc] init];
    });

    testSafeSharedObject.injector = [STRInjector injectorForModule:[[STRTestSafeModule alloc] initWithAdType:adType]];

    return testSafeSharedObject;
}

- (void)prefetchAdForPlacementKey:(NSString *)placementKey delegate:(id<STRAdViewDelegate>)delegate {
    TLog(@"placementKey:%@",placementKey);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] init];
    adPlacement.placementKey = placementKey;
    adPlacement.delegate = delegate;

    __weak id<STRAdViewDelegate>weakDelegate = delegate;

    STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
    STRPromise *adPromise = [generator prefetchAdForPlacement:adPlacement];
    [adPromise then:^id(id value) {
        TLog(@"Prefetch succeeded.");
        if ([weakDelegate respondsToSelector:@selector(didPrefetchAdvertisement:)]) {
            [weakDelegate didPrefetchAdvertisement:(STRAdvertisement *)value];
        }
        return nil;
    } error:^id(NSError *error) {
        TLog(@"Prefetch failed.");
        if ([delegate respondsToSelector:@selector(didFailToPrefetchForPlacementKey:)]) {
            [delegate didFailToPrefetchForPlacementKey:placementKey];
        }
        return nil;
    }];
}

- (BOOL)isAdAvailableForPlacement:(NSString *)placementKey atIndex:(NSInteger)index {
    TLog(@"placementKey:%@ index:%ld", placementKey, (long)index);
    STRAdPlacement *placement = [[STRAdPlacement alloc] init];
    placement.placementKey = placementKey;
    placement.adIndex = index;
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache isAdAvailableForPlacement:placement AndInitializeAd:NO];
}

- (STRAdvertisement *)AdForPlacement:(NSString *)placementKey atIndex:(NSInteger)index {
    TLog(@"placementKey:%@ index:%ld", placementKey, (long)index);
    STRAdPlacement *placement = [[STRAdPlacement alloc] init];
    placement.placementKey = placementKey;
    placement.adIndex = index;
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    if ([adCache isAdAvailableForPlacement:placement AndInitializeAd:YES]) {
        return [adCache fetchCachedAdForPlacement:placement];
    } else {
        return nil;
    }
}

- (NSInteger)totalNumberOfAdsAvailableForPlacement:(NSString *)placementKey {
    TLog(@"placementKey: %@", placementKey);
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:placementKey];
}

- (NSInteger)unassignedNumberOfAdsAvailableForPlacement:(NSString *)placementKey {
    TLog(@"placementKey: %@", placementKey);
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache numberOfUnassignedAdsInQueueForPlacementKey:placementKey];
}

- (void)clearCachedAdsForPlacement:(NSString *)placementKey {
    TLog(@"placementKey: %@", placementKey);
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    [adCache clearAssignedAdsForPlacement:placementKey];
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
                index:(NSInteger)index
             delegate:(id<STRAdViewDelegate>)delegate {
    TLog(@"placementKey:%@ index:%ld", placementKey, (long)index);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:view
                                                            PlacementKey:placementKey
                                                presentingViewController:presentingViewController
                                                                delegate:delegate
                                                                 adIndex:index
                                                            isDirectSold:NO
                                                                 DFPPath:nil
                                                             DFPDeferred:nil];

    STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
    [generator placeAdInPlacement:adPlacement];
}

- (void)placeAdInTableView:(UITableView *)tableView
     adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
              placementKey:(NSString *)placementKey
  presentingViewController:(UIViewController *)presentingViewController
                  adHeight:(CGFloat)adHeight
     articlesBeforeFirstAd:(NSUInteger)articlesBeforeFirstAd
        articlesBetweenAds:(NSUInteger)articlesBetweenAds
                 adSection:(NSInteger)adSection {
    TLog(@"placementKey:%@ adCellIdentifier:%@", placementKey, adCellReuseIdentifier);
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRGridlikeViewDataSourceProxy *dataSourceProxy =
        [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier
                                                                 placementKey:placementKey
                                                     presentingViewController:presentingViewController
                                                                     injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:tableView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:CGSizeMake(0, adHeight)
                             articlesBeforeFirstAd:articlesBeforeFirstAd
                                articlesBetweenAds:articlesBetweenAds
                                         adSection:adSection];
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
                         adSize:(CGSize)adSize
          articlesBeforeFirstAd:(NSUInteger)articlesBeforeFirstAd
             articlesBetweenAds:(NSUInteger)articlesBetweenAds
                      adSection:(NSInteger)adSection {
    TLog(@"placementKey:%@ adCellIdentifier:%@", placementKey, adCellReuseIdentifier);
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator =
        [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRGridlikeViewDataSourceProxy *dataSourceProxy =
        [[STRGridlikeViewDataSourceProxy alloc]initWithAdCellReuseIdentifier:adCellReuseIdentifier
                                                                placementKey:placementKey
                                                    presentingViewController:presentingViewController
                                                                    injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:collectionView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:adSize
                             articlesBeforeFirstAd:articlesBeforeFirstAd
                                articlesBetweenAds:articlesBetweenAds
                                         adSection:adSection];
}

- (NSUInteger)setAdCacheTimeInSeconds:(NSUInteger)seconds {
    TLog(@"");
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache setAdCacheTimeoutInSeconds:seconds];
}
@end
