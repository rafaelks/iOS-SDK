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

- (id)initWithOriginalDataSource:(id<UITableViewDataSource>)originalDataSource
                        adjuster:(STRAdPlacementAdjuster *)adjuster
           adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                    placementKey:(NSString *)placementKey
        presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector;

@end
