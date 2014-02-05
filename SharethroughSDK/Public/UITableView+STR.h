//
//  UITableView+STR.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/3/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

/** 
 Sharethrough-aware alternatives to UITableView's methods for adding/moving/deleting/accessing content. These methods are ad-aware-- they will adjust the index paths that the built in UITableView's methods use so that ad rows aren't adversely affected. Switching to use these methods will mean that users will not have to translate their own index paths before making changes to the UITableView. For methods that affect row count/sections (e.g. -insertRowsAtIndexPaths:) it is required that these alternate methods are called otherwise the SDK will incorrectly render both ads and your content.
 
 These methods will raise exception unless tableview has been set up with -[SharethroughSDK placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:]
 */
@interface UITableView (STR)

/**
 Supports inserting multiple rows while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -insertRowsAtIndexPaths:withRowAnimation:
 
 @param indexPaths An array of NSIndexPath objects each representing a row index and section index that together identify a row in the table view
 @param rowAnimation A constant that either specifies the kind of animation to perform when inserting the cell or requests no animation.
 */

- (void)str_insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation;

/**
 Supports deleting multiple rows while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -deleteRowsAtIndexPaths:withRowAnimation:

 @param indexPaths An array of NSIndexPath objects each representing a row index and section index that together identify a row in the table view
 @param rowAnimation A constant that either specifies the kind of animation to perform when inserting the cell or requests no animation.
 */
- (void)str_deleteRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation;

/**
 Supports moving a row while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -moveRowAtIndexPath:toIndexPath:

 @param indexPath An index path identifying the row to move.
 @param newIndexPath An index path identifying the row that is the destination of the row at indexPath. The existing row at that location slides up or down to an adjoining index position to make room for it.
 */
- (void)str_moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

/**
 Supports inserting a section while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -insertSections:withRowAnimation:

 @param sections An index set that specifies the sections to insert in the receiving table view. If a section already exists at the specified index location, it is moved down one index location.
 @param animation A constant that indicates how the insertion is to be animated, for example, fade in or slide in from the left.
 */
- (void)str_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation;

/**
 Supports deleting a section while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -deleteSections:withRowAnimation:

 @param sections An index set that specifies the sections to delete from the receiving table view. If a section exists after the specified index location, it is moved up one index location.
 @param animation A constant that indicates how the insertion is to be animated, for example, fade in or slide in from the left.
 */
- (void)str_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation;

/**
 Supports moving a section while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -moveSection:toSection:

 @param section The index of the section to move.
 @param newSection The index in the table view that is the destination of the move for the section. The existing section at that location slides up or down to an adjoining index position to make room for it.
 */
- (void)str_moveSection:(NSInteger)section toSection:(NSInteger)newSection;

@end
