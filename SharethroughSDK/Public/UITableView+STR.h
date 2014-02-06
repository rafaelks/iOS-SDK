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

/**---------------------------------------------------------------------------------------
 * @name Methods required to be used instead of corresponding UITableView methods
 *  ---------------------------------------------------------------------------------------
 */

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

/**---------------------------------------------------------------------------------------
 * @name Convenience accessor methods that are ad aware
 *  ---------------------------------------------------------------------------------------
 */

/**
 Retrieves the cell while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -cellForRowAtIndexPath:
 
 @param indexPath The index path locating the row in the receiver.
 @return An object representing a cell of the table or nil if the cell is not visible or indexPath is out of range.
 */
- (UITableViewCell *)str_cellForRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 Retrieves the index path for a cell while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -indexPathForCell:

 @param cell A cell object of the table view.
 @return An index path representing the row and section of the cell or nil if the index path is invalid. Passing in an ad cell to this method will also return nil.
 */
- (NSIndexPath *)str_indexPathForCell:(UITableViewCell *)cell;

/**
 Returns an index path identifying the row and section at the given point while taking it account ad(s) provided by Sharethrough.  Alternate to UITableView's built-in -indexPathForRowAtPoint:
 
 @param point A point in the local coordinate system of the receiver (the table view's bounds).
 @return An index path representing the row and section associated with point or nil if the point is out of the bounds of any row. Passing in a point that corresponds to an ad cell will also return nil.
 */
- (NSIndexPath *)str_indexPathForRowAtPoint:(CGPoint)point;

/**
 Returns an array of index paths each representing a row enclosed by a given rectangle accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -indexPathsForRowsInRect:

 @param rect A rectangle defining an area of the table view in local coordinates.
 @return An array of NSIndexPath objects each representing a row and section index identifying a row within rect. Returns an empty array if there aren’t any rows to return.
 */
- (NSArray *)str_indexPathsForRowsInRect:(CGRect)rect;

/**
 Returns an array of UITableViewCells that are visible in the receiver while accounting for ad(s) provided by Sharethrough.  Alternate to UITableView's built-in -visibleCells
 
 @return An array containing UITableViewCell objects, each representing a visible cell in the receiving table view.
 */
- (NSArray *)str_visibleCellsWithoutAds;

/**
 Returns an array of index paths each identifying a visible row in the receiver while accounting for ad(s) provided by Sharethrough.  Alternate to UITableView's built-in -indexPathsForVisibleRows
 
 @return An array of NSIndexPath objects each representing a row index and section index that together identify a visible row in the table view.
 */
- (NSArray *)str_indexPathsForVisibleRows;

/**
 Returns a drawing area for the index path while accounting for ad(s) provided by Sharethrough.  Alternate to UITableView's built-in -rectForRowAtIndexPath:

 @param indexPath An index path object that identifies a row by its index and its section index.
 @return A rectangle defining the area in which the table view draws the row or CGRectZero if indexPath is invalid.
 */
- (CGRect)str_rectForRowAtIndexPath:(NSIndexPath *)indexPath;


/**---------------------------------------------------------------------------------------
 * @name Convenience methods around selection
 *  ---------------------------------------------------------------------------------------
 */

/**
 Returns an index path identifying the row and section of the selected row while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -indexPathForSelectedRow
 
 @return An index path identifying the row and section indexes of the selected row or nil if the index path is invalid.
 */
- (NSIndexPath *)str_indexPathForSelectedRow;

/**
 Returns the index paths represented the selected rows while accounting for ad(s) provided by Sharethrough. Alternate to UITableView's built-in -indexPathsForSelectedRows
 
 @return An array of index-path objects each identifying a row through its section and row index.
 */

- (NSArray *)str_indexPathsForSelectedRows;

/**
 Selects a row in the receiver identified by index path while accounting for ad(s) provided by Sharethrough, optionally scrolling the row to a location in the receiver. Alternate to UITableView's built-in -selectRowAtIndexPath:animated:scrollPosition:
 
 @param indexPath      An index path identifying a row in the receiver.
 @param animated       if you want to animate the selection and any change in position, NO if the change should be immediate.
 @param scrollPosition A constant that identifies a relative position in the receiving table view (top, middle, bottom) for the row when scrolling concludes.
 */
- (void)str_selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition;

/**
 Deselects a given row identified by index path while accounting for ad(s) provided by Sharethrough, with an option to animate the deselection. Alternate to UITableView's built-in -deselectRowAtIndexPath:animated:
 
 @param indexPath An index path identifying a row in the receiver
 @param animated  YES if you want to animate the deselection and NO if the change should be immediate
 */
-(void)str_deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end
