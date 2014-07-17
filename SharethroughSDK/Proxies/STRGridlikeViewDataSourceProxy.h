//
//  STRGridlikeViewDataSourceProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster, STRInjector;

@interface STRGridlikeViewDataSourceProxy : NSObject<UITableViewDataSource, UICollectionViewDataSource>

@property (nonatomic, weak, readonly) id originalDataSource;
@property (strong, nonatomic, readonly) STRAdPlacementAdjuster *adjuster;
@property (copy, nonatomic, readonly) NSString *adCellReuseIdentifier;
@property (copy, nonatomic, readonly) NSString *placementKey;
@property (weak, nonatomic, readonly) UIViewController *presentingViewController;
@property (weak, nonatomic, readonly) STRInjector *injector;

- (id)initWithOriginalDataSource:(id)originalDataSource
                        adjuster:(STRAdPlacementAdjuster *)adjuster
           adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                    placementKey:(NSString *)placementKey
        presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector;

- (instancetype)copyWithNewDataSource:(id)newDataSource;

- (void)prefetchAdForGridLikeView:(id)gridlikeView;

@end
