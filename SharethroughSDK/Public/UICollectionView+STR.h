//
//  UICollectionView+STR.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Sharethrough-aware alternatives to UICollectionView's methods for adding/moving/deleting/accessing content. These methods are ad-aware-- they will adjust the index paths that the built in UICollectionView's methods use so that ad rows aren't adversely affected. Switching to use these methods will mean that users will not have to translate their own index paths before making changes to the UICollectionView. For methods that affect row count/sections (e.g. -insertRowsAtIndexPaths:) it is required that these alternate methods are called otherwise the SDK will incorrectly render both ads and your content.

 These methods will raise exception unless collectionview has been set up with -[SharethroughSDK placeAdInCollectionView:adCellReuseIdentifier:placementKey:presentingViewController:adSize:adInitialIndexPath:] */
@interface UICollectionView (STR)

/**--------------------------------------------------------------------------------------------------
 * @name Methods required to be used instead of corresponding UICollectionView methods that adjust content
 *  -------------------------------------------------------------------------------------------------
 */

/**
    Preferred method of dequeuing UICollectionViewCells for collection views that have been processed through SharethroughSDK.
    Seriously, use this method instead of the built-in -dequeueReusableCellWithReuseIdentifier:forIndexPath:.


 @param identifier reusable cell identifier
 @param indexPath  indexPath passed into -collectionView:cellForItemAtIndexPath:

 @return a valid UICollectionViewCell
 */
- (id)str_dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

/**
 Supports inserting multiple items while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -insertItemsAtIndexPaths:

 @param indexPaths An array of NSIndexPath objects each representing an item in the collection view
 */
- (void)str_insertItemsAtIndexPaths:(NSArray *)indexPaths;

/**
 Supports deleting multiple items while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -deleteItemsAtIndexPaths:

 @param indexPaths An array of NSIndexPath objects each representing an item in the collection view
 */
- (void)str_deleteItemsAtIndexPaths:(NSArray *)indexPaths;

/**
 Supports moving an item while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -moveItemAtIndexPath:toIndexPath:

 @param indexPath An index path identifying the item to move.
 @param newIndexPath An index path identifying the item that is the destination of the index at indexPath. The existing row at that location slides up or down to an adjoining index position to make room for it.
 */
- (void)str_moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

/**
 Reloads the items and sections of the receiver. Previous ad(s) will be removed and replaced by an ad at the provided adIndexPath. Alternate to UICollectionView's built-in -reloadData

 @param adIndexPath The index path to place an ad in. This index path represents where the ad will reside in the collection view. Pass nil to let the SharethroughSDK choose a default location.
 */
- (void)str_reloadDataWithAdIndexPath:(NSIndexPath *)adIndexPath;

/**
 Reloads the specified sections while accounting for ad(s) provided by Sharethrough. If an ad's location is now invalid (because the section has fewer rows), the ad will be placed at the bottom of its previous section. Alternate to UICollectionView's built-in -reloadSections:

 @param sections  An index set identifying the sections to reload.
 */
- (void)str_reloadSections:(NSIndexSet *)sections;

/**
 Reloads the specified items while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -reloadItemsAtIndexPaths:withRowAnimation:

 @param indexPaths An array of NSIndexPath objects identifying the rows to reload.
 */
- (void)str_reloadItemsAtIndexPaths:(NSArray *)indexPaths;



/**---------------------------------------------------------------------------------------
 * @name Methods required to be used instead of corresponding UITableView methods for managing dataSource/delegate
 *  ---------------------------------------------------------------------------------------
 */

/**
 Getter for object that acts as the data source of the receiving collection view.
 Sharethrough-aware alternate to UICollectionView's -dataSource.

 @return collectionview's datasource
 */
- (id<UICollectionViewDataSource>)str_dataSource;

/**
 Setter for the object that acts as the data source of the receiving collection view.
 Sharethrough-aware alternate to UICollectionView's -setDataSource:.

 @param dataSource new datasource for the collectionview
 */
- (void)str_setDataSource:(id<UICollectionViewDataSource>)dataSource;

/**
 Getter for the object that acts as the delegate of the receiving collection view.
 Sharethrough-aware alternate to UICollectionView's -delegate.

 @return collectionview's delegate
 */
- (id<UICollectionViewDelegate>)str_delegate;

/**
 Setter for the object that acts as the delegate of the receiving collection view.
 Sharethrough-aware alternate to UICollectionView's -setDelegate.

 @param delegate new delegate for the collectionview
 */
- (void)str_setDelegate:(id<UICollectionViewDelegate>)delegate;


/**---------------------------------------------------------------------------------------
 * @name Convenience accessor methods that are ad aware
 *  ---------------------------------------------------------------------------------------
 */

/**
 Returns the number of items in the specified section, excluding ads added by SharethroughSDK.
 Alternative to -numberOfItemsInSection:
 
 @param section The index of the section for which you want a count of the items.
 
 @return The number of items in the specified section
 */
- (NSInteger)str_numberOfItemsInSection:(NSInteger)section;

/**
 Returns an array of visible cells currently displayed by the collection view, excluding ads added by SharethroughSDK.
 Alternative to -visibleCells
 
 @return An array of UICollectionViewCell objects.
 */
- (NSArray *)str_visibleCellsWithoutAds;

/**
 *  Returns the visible cell object at the specified index path, while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -cellForItemAtIndexPath:
 *
 *  @param indexPath The index path that specifies the section and item number of the cell.
 *
 *  @return The cell object at the corresponding index path or nil if the cell is not visible or indexPath is out of range.
 */
- (UICollectionViewCell *)str_cellForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 *  Returns an array of the visible items in the collection view, while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -indexPathsForVisibleItems
 *
 *  @return An array of NSIndexPath objects, each of which corresponds to a visible cell in the collection view. This array does not include any supplementary views that are currently visible. If there are no visible non-ad items, this method returns an empty array.
 */
- (NSArray *)str_indexPathsForVisibleItems;

/**
 *  Returns the index path of the specified cell, while accounting for ad(s) provided by Sharethrough. Alternate to UICollectionView's built-in -indexPathForCell.
 *
 *  @param cell The cell object whose index path you want.
 *
 *  @return The index path of the cell or nil if the specified cell is not in the collection view. If passed in an ad cell, then this will return nil.
 */
- (NSIndexPath *)str_indexPathForCell:(UICollectionViewCell *)cell;

/**
 *  Returns the index path of the cell at the specified point, while accounting for ad(s) provided by Sharethrough

    @param point A point in the local coordinate system of the receiver (the table view's bounds).
    @return An index path representing the row and section associated with point or nil if the point is out of the bounds of any row. Passing in a point that corresponds to an ad cell will also return nil.
 */
- (NSIndexPath *)str_indexPathForItemAtPoint:(CGPoint)point;

/**
 Scrolls the collection view contents until the specified item is visible, while accounting for ad(s) provided by Sharethrough.
 
 @param indexPath      The index path of the item to scroll into view.
 @param scrollPosition An option that specifies where the item should be positioned when scrolling finishes.
 @param animated       Specify YES to animate the scrolling behavior or NO to adjust the scroll view’s visible content immediately.
 */
- (void)str_scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

/**
 Returns the index paths for the selected items, while accounting for ad(s) provided by Sharethrough
 
 @return An array of NSIndexPath objects, each of which corresponds to a visible cell in the collection view
 */
- (NSArray *)str_indexPathsForSelectedItems;

/**
 Selects the item at the specified index path (while accounting for ad(s) provided by Sharethrough) and optionally scrolls it into view.
 
 @param indexPath      The index path of the item to select. Specifying nil for this parameter clears the current selection
 @param animated       Specify YES to animate the change in the selection or NO to make the change without animating it
 @param scrollPosition An option that specifies where the item should be positioned when scrolling finishes
 */
- (void)str_selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition;


/**
 *  Deselects the item at the specified index, while accounting for ad(s) provided by Sharethrough
 *
 *  @param indexPath The index path of the item to select. Specifying nil for this parameter removes the current selection
 *  @param animated  Specify YES to animate the change in the selection or NO to make the change without animating it
 */
- (void)str_deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
@end
