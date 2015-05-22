//
//  SharethroughSDKDFP.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 9/4/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "SharethroughSDK+DFP.h"

#import "STRInjector.h"
#import "STRAdGenerator.h"
#import "STRAdPlacement.h"
#import "STRGridlikeViewAdGenerator.h"
#import "STRDFPGridlikeViewDataSourceProxy.h"
#import "STRFakeAdGenerator.h"
#import "STRBeaconService.h"
#import "STRAdService.h"
#import "STRDFPAdGenerator.h"
#import "STRDFPAppModule.h"
#import "STRAdCache.h"
#import "STRDFPManager.h"
#import "STRLogging.h"

@interface SharethroughSDKDFP ()

@property (nonatomic, strong) STRInjector *injector;

@end

@implementation SharethroughSDKDFP

+ (instancetype)sharedInstance {
    __strong static SharethroughSDKDFP *sharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
        TLog(@"WARNING: This version of the SDK was built with trace logging for debugging and integration purposes and should not be used in production.");
    });

    return sharedObject;
}

- (id)init {
    self = [super init];
    if (self) {
        self.injector = [STRInjector injectorForModule:[STRDFPAppModule new]];
        [self.injector getInstance:[STRDFPAdGenerator class]];
        STRDFPManager *dfpManager = [STRDFPManager sharedInstance];
        dfpManager.injector = self.injector;

        NSString *model = [[UIDevice currentDevice] model];
        if ([model hasSuffix:@"Simulator"]) {
            NSLog(@"WARNING using %@ is not supported for DFP because only test ads are available", model);
        }
    }
    return self;
}

- (void)prefetchAdForPlacementKey:(NSString *)placementKey delegate:(id<STRAdViewDelegate>)delegate {
    TLog(@"placementKey:%@",placementKey);

    STRDeferred *deferred = [STRDeferred defer];

    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] init];
    adPlacement.presentingViewController = [UIViewController new];
    adPlacement.placementKey = placementKey;
    adPlacement.delegate = delegate;
    adPlacement.DFPDeferred = deferred;

    [deferred.promise then:^id(id value) {
        TLog(@"Prefetch succeeded.");
        if ([delegate respondsToSelector:@selector(adView:didFetchAdForPlacementKey:atIndex:)]) {
            [delegate adView:nil didFetchAdForPlacementKey:placementKey atIndex:0];
        }
        return value;
    } error:^id(NSError *error) {
        TLog(@"Prefetch failed.");
        if ([delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:atIndex:)]) {
            [delegate adView:nil didFailToFetchAdForPlacementKey:placementKey atIndex:0];
        }
        return error;
    }];

    STRDFPAdGenerator *adGenerator = [self.injector getInstance:[STRDFPAdGenerator class]];
    [adGenerator placeAdInPlacement:adPlacement];
}

- (BOOL)isAdAvailableForPlacement:(NSString *)placementKey atIndex:(NSInteger)index {
    TLog(@"placementKey:%@ index:%ld", placementKey, (long)index);
    STRAdPlacement *placement = [[STRAdPlacement alloc] init];
    placement.placementKey = placementKey;
    placement.adIndex = index;
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache isAdAvailableForPlacement:placement];
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
              dfpPath:(NSString *)dfpPath
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {
    TLog(@"placementKey:%@ index:%ld", placementKey, (long)index);
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:view
                                                            PlacementKey:placementKey
                                                presentingViewController:presentingViewController
                                                                delegate:delegate
                                                                 adIndex:0
                                                            isDirectSold:YES
                                                                 DFPPath:dfpPath
                                                             DFPDeferred:nil];

    STRDFPAdGenerator *generator = [self.injector getInstance:[STRDFPAdGenerator class]];
    [generator placeAdInPlacement:adPlacement];
}

- (void)placeAdInTableView:(UITableView *)tableView
     adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
              placementKey:(NSString *)placementKey
  presentingViewController:(UIViewController *)presentingViewController
                  adHeight:(CGFloat)adHeight
        adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    TLog(@"placementKey:%@ adCellIdentifier:%@", placementKey, adCellReuseIdentifier);
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRDFPGridlikeViewDataSourceProxy *dataSourceProxy = [[STRDFPGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier placementKey:placementKey presentingViewController:presentingViewController injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:tableView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:CGSizeMake(0, adHeight)
                             articlesBeforeFirstAd:adInitialIndexPath.row
                                articlesBetweenAds:1000000
                                         adSection:adInitialIndexPath.section];
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
                         adSize:(CGSize)adSize
             adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    TLog(@"placementKey:%@ adCellIdentifier:%@", placementKey, adCellReuseIdentifier);
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRDFPGridlikeViewDataSourceProxy *dataSourceProxy = [[STRDFPGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier
                                                                                                                     placementKey:placementKey
                                                                                                         presentingViewController:presentingViewController
                                                                                                                         injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:collectionView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:adSize
                             articlesBeforeFirstAd:adInitialIndexPath.row
                                articlesBetweenAds:1000000
                                         adSection:adInitialIndexPath.section];
}

- (NSUInteger)setAdCacheTimeInSeconds:(NSUInteger)seconds {
    TLog(@"");
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache setAdCacheTimeoutInSeconds:seconds];
}
@end
