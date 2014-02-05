//
//  UITableView+STR.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/3/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 
 Sharethrough-aware alternatives to UITableView's methods for adding/moving/deleting/accessing content. These methods are ad-aware-- they will adjust the index paths that the built in UITableView's methods use so that ad rows aren't adversely affected. Switching to use these methods will mean that users will not have to translate their own index paths before making changes to the UITableView.
 */
@interface UITableView (STR)

/**
 Supports inserting multiple rows while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -insertRowsAtIndexPaths:withRowAnimation:
 
 @param indexPaths NSArray with indexPaths to insert rows at
 @param rowAnimation type of row animation
 @warning will raise exception unless tableview has been set up with -[SharethroughSDK placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:]
 */

- (void)str_insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation;

/**
 Supports deleting multiple rows while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -deleteRowsAtIndexPaths:withRowAnimation:

 @param indexPaths NSArray with indexPaths to delete rows at
 @param rowAnimation type of row animation
 @warning will raise exception unless tableview has been set up with -[SharethroughSDK placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:]
 */
- (void)str_deleteRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation;

- (void)str_moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

@end
