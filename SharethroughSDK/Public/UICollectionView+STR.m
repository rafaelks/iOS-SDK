//
//  UICollectionView+STR.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "UICollectionView+STR.h"
#import "STRAdPlacementAdjuster.h"
#import <objc/runtime.h>
#import "STRCollectionViewAdGenerator.h"

extern const char * const STRCollectionViewAdGeneratorKey;

@implementation UICollectionView (STR)

- (id)str_dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSIndexPath *trueIndexPath = [adjuster trueIndexPath:indexPath];

    return [self dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:trueIndexPath];
}

- (void)str_insertItemsAtIndexPaths:(NSArray *)indexPaths {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSArray *trueIndexPaths = [adjuster willInsertRowsAtExternalIndexPaths:indexPaths];
    [self insertItemsAtIndexPaths:trueIndexPaths];
}

- (void)str_moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSArray *indexPaths = [adjuster willMoveRowAtExternalIndexPath:indexPath toExternalIndexPath:newIndexPath];
    [self moveItemAtIndexPath:[indexPaths firstObject] toIndexPath:[indexPaths lastObject]];
}

- (void)str_deleteItemsAtIndexPaths:(NSArray *)indexPaths {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];

    NSArray *trueIndexPaths = [adjuster willDeleteRowsAtExternalIndexPaths:indexPaths];
    [self deleteItemsAtIndexPaths:trueIndexPaths];
}

- (NSInteger)str_numberOfItemsInSection:(NSInteger)section {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];

    return [self numberOfItemsInSection:section] - [adjuster numberOfAdsInSection:section];
}

- (NSArray *)str_visibleCellsWithoutAds {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];

    NSMutableArray *visibleCells = [[self visibleCells] mutableCopy];
    [visibleCells removeObject:[self cellForItemAtIndexPath:adjuster.adIndexPath]];

    return [visibleCells copy];
}

- (UICollectionViewCell *)str_cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSIndexPath *trueIndexPath = [adjuster trueIndexPath:indexPath];
    return [self cellForItemAtIndexPath:trueIndexPath];
}

- (NSArray *)str_indexPathsForVisibleItems {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    return [adjuster externalIndexPaths:[self indexPathsForVisibleItems]];
}

- (NSIndexPath *)str_indexPathForCell:(UICollectionViewCell *)cell {
    return [[self str_ensureAdjuster] externalIndexPath:[self indexPathForCell:cell]];
}

- (NSIndexPath *)str_indexPathForItemAtPoint:(CGPoint)point {
    NSIndexPath *trueIndexPath = [self indexPathForItemAtPoint:point];
    return [[self str_ensureAdjuster] externalIndexPath:trueIndexPath];
}

#pragma mark - Private

- (STRAdPlacementAdjuster *)str_ensureAdjuster {
    STRCollectionViewAdGenerator *adGenerator = objc_getAssociatedObject(self, STRCollectionViewAdGeneratorKey);
    if (!adGenerator) {
        [NSException raise:@"STRCollectionViewApiImproperSetup" format:@"Called %@ on a collectionview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInCollectionView:adCellReuseIdentifier:placementKey:presentingViewController:))];
    }

    return adGenerator.adjuster;
}


@end
