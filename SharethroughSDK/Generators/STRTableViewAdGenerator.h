//
//  STRTableViewAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SharethroughSDK, STRInjector, STRAdPlacementAdjuster;

@interface STRTableViewAdGenerator : NSObject

@property (nonatomic, strong, readonly) STRAdPlacementAdjuster *adjuster;

- (id)initWithInjector:(STRInjector *)injector;

- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight adStartingIndexPath:(NSIndexPath *)adStartingIndexPath;

@end