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
#import "STRGridlikeViewAdGenerator.h"
#import "STRFakeAdGenerator.h"
#import "STRBeaconService.h"
#import "STRAdService.h"

@interface SharethroughSDK ()

@property (nonatomic, strong) STRInjector *injector;

@end

@implementation SharethroughSDK

+ (instancetype)sharedInstance {

    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
        [sharedObject configure];
    });

    return sharedObject;
}

+ (instancetype)testSafeInstanceWithAdType:(STRFakeAdType)adType {
    SharethroughSDK *sdk = [[self alloc] init];
    [sdk configure];

    STRAdGenerator *fakeAdGenerator = [[STRFakeAdGenerator alloc] initWithAdType:adType withInjector:sdk.injector];
    [sdk.injector bind:[STRAdGenerator class] toInstance:fakeAdGenerator];
    [sdk.injector bind:[STRBeaconService class] toInstance:[NSNull null]];
    [sdk.injector bind:[STRAdService class] toInstance:[NSNull null]];

    return sdk;
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate {
    STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
    [generator placeAdInView:view
                placementKey:placementKey
    presentingViewController:presentingViewController
                    delegate:delegate];
}

- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    [gridlikeViewAdGenerator placeAdInGridlikeView:tableView
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                          adHeight:adHeight
                                adInitialIndexPath:adInitialIndexPath];
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    STRGridlikeViewAdGenerator *gridlikeViewAdGenerator = [self.injector getInstance:[STRGridlikeViewAdGenerator class]];
    [gridlikeViewAdGenerator placeAdInGridlikeView:collectionView
                             adCellReuseIdentifier:adCellReuseIdentifier
                                      placementKey:placementKey
                          presentingViewController:presentingViewController
                                          adHeight:0
                                adInitialIndexPath:adInitialIndexPath];
}

#pragma mark - Private

- (void)configure {
    self.injector = [STRInjector injectorForModule:[STRAppModule new]];
}
@end
