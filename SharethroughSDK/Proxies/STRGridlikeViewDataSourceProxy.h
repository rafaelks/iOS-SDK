//
//  STRGridlikeViewDataSourceProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STRAdViewDelegate.h"

@class STRAdPlacementAdjuster, STRInjector, STRAdPlacement;

@interface STRGridlikeViewDataSourceProxy : NSObject<UITableViewDataSource, UICollectionViewDataSource, STRAdViewDelegate>

@property (nonatomic, weak) id originalDataSource;
@property (strong, nonatomic) STRAdPlacementAdjuster *adjuster;

@property (copy, nonatomic, readonly) NSString *adCellReuseIdentifier;
@property (strong, nonatomic, readonly) STRAdPlacement *placement;
@property (assign, nonatomic) NSInteger numAdsInView;
@property (weak, nonatomic, readonly) STRInjector *injector;

- (id)initWithAdCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                        adPlacement:(STRAdPlacement *)placement
                           injector:(STRInjector *)injector;

- (instancetype)copyWithNewDataSource:(id)newDataSource;

- (void)prefetchAdForGridLikeView:(id)gridlikeView;
- (UITableViewCell *)adCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (UICollectionViewCell *)adCellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath;

@end
