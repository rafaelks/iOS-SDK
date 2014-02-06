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

/**
 *  Preferred method of dequeuing UICollectionViewCells for collection views that have been processed through SharethroughSDK.
    Seriously, use this method instead of the built-in -dequeueReusableCellWithReuseIdentifier:forIndexPath:.


 @param identifier reusable cell identifier
 @param indexPath  indexPath passed into -collectionView:cellForItemAtIndexPath:

 @return a valid UICollectionViewCell
 */
- (id)str_dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

@end