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

@interface SharethroughSDKDFP ()

@property (nonatomic, strong) STRInjector *injector;

@end

@implementation SharethroughSDKDFP

+ (instancetype)sharedInstance {
    __strong static SharethroughSDKDFP *sharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
        sharedObject.injector = [STRInjector injectorForModule:[STRDFPAppModule new]];
        [sharedObject.injector getInstance:[STRDFPAdGenerator class]];
        STRDFPManager *dfpManager = [STRDFPManager sharedInstance];
        dfpManager.injector = sharedObject.injector;
    });

    return sharedObject;
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
              dfpPath:(NSString *)dfpPath
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {

    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:view
                                                            PlacementKey:placementKey
                                                presentingViewController:presentingViewController
                                                                delegate:delegate
                                                                 adIndex:0
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
/*
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    STRDFPGridlikeViewDataSourceProxy *dataSourceProxy = [[STRDFPGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier placementKey:placementKey presentingViewController:presentingViewController injector:self.injector];

    [gridlikeViewAdGenerator placeAdInGridlikeView:tableView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:CGSizeMake(0, adHeight)
                                adInitialIndexPath:adInitialIndexPath];
 */
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
                         adSize:(CGSize)adSize
             adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {

    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
STRDFPGridlikeViewDataSourceProxy *dataSourceProxy = [[STRDFPGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier placementKey:placementKey presentingViewController:presentingViewController injector:self.injector];
/*
    [gridlikeViewAdGenerator placeAdInGridlikeView:collectionView
                                   dataSourceProxy:dataSourceProxy
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:adSize
                                adInitialIndexPath:adInitialIndexPath];
 */
}

- (NSUInteger)setAdCacheTimeInSeconds:(NSUInteger)seconds {
    STRAdCache *adCache = [self.injector getInstance:[STRAdCache class]];
    return [adCache setAdCacheTimeoutInSeconds:seconds];
}
@end
