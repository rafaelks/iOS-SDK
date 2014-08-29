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
#import "STRFakeAdGenerator.h"
#import "STRBeaconService.h"
#import "STRAdService.h"
#import "STRTestSafeModule.h"
#import "STRDFPAdGenerator.h"

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
        [sharedObject.injector getInstance:[STRGridlikeViewAdGenerator class]];
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

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate {
    [self placeAdInView:view usingDFP:NO placementKey:placementKey presentingViewController:presentingViewController delegate:delegate];
}

- (void)placeAdInView:(UIView<STRAdView> *)view usingDFP:(BOOL)useDFP placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate {

    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWith:view placementKey:placementKey presentingViewController:presentingViewController delegate:delegate];

    if (useDFP) {
        STRDFPAdGenerator *generator = [self.injector getInstance:[STRDFPAdGenerator class]];
        [generator placeAdInPlacement:adPlacement];
    } else {
        STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
        [generator placeAdInPlacement:adPlacement];
    }
}

- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    [gridlikeViewAdGenerator placeAdInGridlikeView:tableView
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:CGSizeMake(0, adHeight)
                                adInitialIndexPath:adInitialIndexPath];
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adSize:(CGSize)adSize adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    [gridlikeViewAdGenerator placeAdInGridlikeView:collectionView
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                            adSize:adSize
                                adInitialIndexPath:adInitialIndexPath];
}

@end
