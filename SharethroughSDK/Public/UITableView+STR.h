//
//  UITableView+STR.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/3/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 
 Sharethrough-aware alternatives to UITableView's methods for adding/moving/deleting content.
 */
@interface UITableView (STR)

/**
 Supports inserting multiple rows while accounting for ad(s) provided by Sharethrough. Preferred over UITableView's built-in -insertRowsAtIndexPaths:withRowAnimation:
 
 @param indexPaths NSArray with indexPaths to insert rows at
 @param rowAnimation type of row animation
 @warning will raise exception unless tableview has been set up with -[SharethroughSDK placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:]
 */

- (void)str_insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation;
@end
