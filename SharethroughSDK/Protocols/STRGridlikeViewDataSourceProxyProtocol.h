//
//  STRGridlikeViewDataSourceProxyProtocol.h
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 9/4/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster, STRInjector;

@protocol STRGridlikeViewDataSourceProxyProtocol <UITableViewDataSource, UICollectionViewDataSource>

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
