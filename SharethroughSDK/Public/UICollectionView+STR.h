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

 These methods will raise exception unless collectionview has been set up with -[SharethroughSDK placeAdInCollectionView:adCellReuseIdentifier:placementKey:presentingViewController:] */
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

- (NSIndexPath *)str_indexPathForItemAtPoint:(CGPoint)point;

@end
