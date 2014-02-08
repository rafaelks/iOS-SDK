//
//  STRTableViewDataSourceProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster, STRInjector;

@interface STRTableViewDataSourceProxy : NSObject<UITableViewDataSource>

@property (nonatomic, weak, readonly) id<UITableViewDataSource> originalDataSource;
@property (strong, nonatomic, readonly) STRAdPlacementAdjuster *adjuster;
@property (copy, nonatomic, readonly) NSString *adCellReuseIdentifier;
@property (copy, nonatomic, readonly) NSString *placementKey;
@property (weak, nonatomic, readonly) UIViewController *presentingViewController;
@property (weak, nonatomic, readonly) STRInjector *injector;

- (id)initWithOriginalDataSource:(id<UITableViewDataSource>)originalDataSource
                        adjuster:(STRAdPlacementAdjuster *)adjuster
           adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                    placementKey:(NSString *)placementKey
        presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector;

- (instancetype)proxyWithNewDataSource:(id)newDataSource;

@end
