//
//  STRCollectionViewDataSourceProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/12/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster, STRInjector;

@interface STRCollectionViewDataSourceProxy : NSObject<UICollectionViewDataSource>
@property (strong, nonatomic, readonly) STRAdPlacementAdjuster *adjuster;
@property (copy, nonatomic, readonly) NSString *adCellReuseIdentifier;
@property (copy, nonatomic, readonly) NSString *placementKey;
@property (weak, nonatomic, readonly) UIViewController *presentingViewController;
@property (weak, nonatomic, readonly) STRInjector *injector;

- (id)initWithOriginalDataSource:(id<UICollectionViewDataSource>)originalDataSource
                        adjuster:(STRAdPlacementAdjuster *)adjuster
           adCellReuseIdentifier:(NSString *)reuseIdentifier
                    placementKey:(NSString *)placementKey
        presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector;

- (instancetype)copyWithNewDataSource:(id<UICollectionViewDataSource>)newDataSource;

@property (nonatomic, weak, readonly)id<UICollectionViewDataSource> originalDataSource;

@end
