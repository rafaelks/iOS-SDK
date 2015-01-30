//
//  STRGridlikeViewDataSourceProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STRAdViewDelegate.h"

@class STRAdPlacementAdjuster, STRInjector;

@interface STRGridlikeViewDataSourceProxy : NSObject<UITableViewDataSource, UICollectionViewDataSource, STRAdViewDelegate>

@property (nonatomic, weak) id originalDataSource;
@property (strong, nonatomic) STRAdPlacementAdjuster *adjuster;

@property (copy, nonatomic, readonly) NSString *adCellReuseIdentifier;
@property (copy, nonatomic, readonly) NSString *placementKey;
@property (weak, nonatomic, readonly) UIViewController *presentingViewController;
@property (weak, nonatomic, readonly) STRInjector *injector;

- (id)initWithAdCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                       placementKey:(NSString *)placementKey
           presentingViewController:(UIViewController *)presentingViewController
                           injector:(STRInjector *)injector;

- (instancetype)copyWithNewDataSource:(id)newDataSource;

- (void)prefetchAdForGridLikeView:(id)gridlikeView atIndex:(NSInteger)index;

@end
