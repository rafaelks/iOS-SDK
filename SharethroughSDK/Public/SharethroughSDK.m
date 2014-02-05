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
#import "STRTableViewAdGenerator.h"
#import "STRCollectionViewAdGenerator.h"

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

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate {

    STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
    [generator placeAdInView:view
                placementKey:placementKey
    presentingViewController:presentingViewController
                    delegate:delegate];
}

- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight {

    STRTableViewAdGenerator *tableViewAdGenerator = [self.injector getInstance:[STRTableViewAdGenerator class]];
    [tableViewAdGenerator placeAdInTableView:tableView
                       adCellReuseIdentifier:adCellReuseIdentifier
                                placementKey:placementKey
                    presentingViewController:presentingViewController
                                    adHeight:adHeight];
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController {

    STRCollectionViewAdGenerator *collectionViewAdGenerator = [self.injector getInstance:[STRCollectionViewAdGenerator class]];
    [collectionViewAdGenerator placeAdInCollectionView:collectionView
                                 adCellReuseIdentifier:adCellReuseIdentifier
                                          placementKey:placementKey
                              presentingViewController:presentingViewController];
}

#pragma mark - Private

- (void)configure {
    self.injector = [STRInjector injectorForModule:[STRAppModule new]];
}
@end
