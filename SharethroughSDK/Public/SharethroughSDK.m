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

- (void)prefetchAdForPlacementKey:(NSString *)placementKey customProperties:(NSDictionary *)customProperties delegate:(id<STRAdViewDelegate>)delegate {
    TLog(@"placementKey:%@",placementKey);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] init];
    adPlacement.customProperties = customProperties;
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

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
                index:(NSInteger)index
     customProperties:(NSDictionary *)customProperties
             delegate:(id<STRAdViewDelegate>)delegate {
    TLog(@"placementKey:%@ index:%ld", placementKey, (long)index);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:view
                                                            PlacementKey:placementKey
                                                presentingViewController:presentingViewController
                                                                delegate:delegate
                                                                 adIndex:index
                                                            isDirectSold:NO
                                                        customProperties:customProperties];

    STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
    [generator placeAdInPlacement:adPlacement];
}

- (void)placeAdInTableView:(UITableView *)tableView
     adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
              placementKey:(NSString *)placementKey
  presentingViewController:(UIViewController *)presentingViewController
                  adHeight:(CGFloat)adHeight
                 adSection:(NSInteger)adSection
          customProperties:(NSDictionary *)customProperties {
    TLog(@"placementKey:%@ adCellIdentifier:%@", placementKey, adCellReuseIdentifier);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:nil
                                                            PlacementKey:placementKey
                                                presentingViewController:presentingViewController
                                                                delegate:nil
                                                                 adIndex:0
                                                            isDirectSold:NO
                                                        customProperties:customProperties];

    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRGridlikeViewDataSourceProxy *dataSourceProxy =
    [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier
                                                                adPlacement:adPlacement
                                                                 injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:tableView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:CGSizeMake(0, adHeight)
                                         adSection:adSection];
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
                         adSize:(CGSize)adSize
                      adSection:(NSInteger)adSection
               customProperties:(NSDictionary *)customProperties {
    TLog(@"placementKey:%@ adCellIdentifier:%@", placementKey, adCellReuseIdentifier);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:nil
                                                            PlacementKey:placementKey
                                                presentingViewController:presentingViewController
                                                                delegate:nil
                                                                 adIndex:0
                                                            isDirectSold:NO
                                                        customProperties:customProperties];
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator =
    [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRGridlikeViewDataSourceProxy *dataSourceProxy =
    [[STRGridlikeViewDataSourceProxy alloc]initWithAdCellReuseIdentifier:adCellReuseIdentifier
                                                               adPlacement:adPlacement
                                                                injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:collectionView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:adSize
                                         adSection:adSection];
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

- (NSUInteger)setAdCacheTimeInSeconds:(NSUInteger)seconds {
    TLog(@"");
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache setAdCacheTimeoutInSeconds:seconds];
}
@end
