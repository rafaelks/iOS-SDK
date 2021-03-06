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
#import "STRGridlikeViewAdGenerator.h"
#import "SharethroughSDK.h"
#import "STRLogging.h"

extern const char * const STRGridlikeViewAdGeneratorKey;

@implementation UICollectionView (STR)

- (id)str_dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    STRGridlikeViewAdGenerator *adGenerator = objc_getAssociatedObject(self, STRGridlikeViewAdGeneratorKey);
    if (adGenerator) {
        STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
        NSIndexPath *trueIndexPath = [adjuster indexPathIncludingAds:indexPath];

        return [self dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:trueIndexPath];
    } else {
        NSLog(@"WARNING: Called %@ on a collectionview that was not setup through SharethroughSDK %@. Did you intend to place an ad in this UICollectionView? If not, use UICollectionView's built-in -dequeueReusableCellWithReuseIdentifier: method", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInGridlikeView:dataSourceProxy:adCellReuseIdentifier:placementKey:presentingViewController:adSize:adSection:)));
        return [self dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    }
}

- (void)str_insertItemsAtIndexPaths:(NSArray *)indexPaths {
    TLog(@"");
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSArray *trueIndexPaths = [adjuster indexPathsIncludingAds:indexPaths];
    [self insertItemsAtIndexPaths:trueIndexPaths];
}

- (void)str_moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    TLog(@"");
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSArray *indexPaths = [adjuster willMoveRowAtExternalIndexPath:indexPath toExternalIndexPath:newIndexPath];
    [self moveItemAtIndexPath:[indexPaths firstObject] toIndexPath:[indexPaths lastObject]];
}

- (void)str_deleteItemsAtIndexPaths:(NSArray *)indexPaths {
    TLog(@"");
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];

    NSArray *trueIndexPaths = [adjuster indexPathsIncludingAds:indexPaths];
    [self deleteItemsAtIndexPaths:trueIndexPaths];
}

- (NSInteger)str_numberOfItemsInSection:(NSInteger)section {
    TLog(@"");
    return  [self numberOfItemsInSection:section] - [[self str_ensureAdjuster] getLastCalculatedNumberOfAdsInSection:section];
}

- (NSArray *)str_visibleCellsWithoutAds {
    TLog(@"");
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];

    NSMutableArray *visibleCells = [[self visibleCells] mutableCopy];
    NSArray *visibleCellsIdexPaths = [self indexPathsForVisibleItems];
    for (NSUInteger i = 0; i < [visibleCellsIdexPaths count]; ++i) {
        NSIndexPath *indexPath = visibleCellsIdexPaths[i];
        if ([adjuster isAdAtIndexPath:indexPath]) {
            [visibleCells removeObjectAtIndex:i];
        }
    }

    return [visibleCells copy];
}

- (UICollectionViewCell *)str_cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    TLog(@"");
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSIndexPath *trueIndexPath = [adjuster indexPathIncludingAds:indexPath];
    return [self cellForItemAtIndexPath:trueIndexPath];
}

- (NSArray *)str_indexPathsForVisibleItems {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathsWithoutAds:[self indexPathsForVisibleItems]];
}

- (NSIndexPath *)str_indexPathForCell:(UICollectionViewCell *)cell {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathWithoutAds:[self indexPathForCell:cell]];
}

- (NSIndexPath *)str_indexPathForItemAtPoint:(CGPoint)point {
    TLog(@"");
    NSIndexPath *trueIndexPath = [self indexPathForItemAtPoint:point];
    return [[self str_ensureAdjuster] indexPathWithoutAds:trueIndexPath];
}

- (void)str_reloadData {
    TLog(@"");
    [self reloadData];
}

- (void)str_reloadSections:(NSIndexSet *)sections {
    TLog(@"");
    [self reloadSections:sections];
}

- (void)str_reloadItemsAtIndexPaths:(NSArray *)indexPaths {
    TLog(@"");
    [self reloadItemsAtIndexPaths:[[self str_ensureAdjuster] indexPathsIncludingAds:indexPaths]];

}

- (void)str_scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {
    TLog(@"");
    [self scrollToItemAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath] atScrollPosition:scrollPosition animated:animated];
}

- (NSArray *)str_indexPathsForSelectedItems {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathsWithoutAds:[self indexPathsForSelectedItems]];
}

- (void)str_selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition {
    TLog(@"");
    NSIndexPath *adjustedIndexPath = [[self str_ensureAdjuster] indexPathIncludingAds:indexPath];

    [self selectItemAtIndexPath:adjustedIndexPath animated:animated scrollPosition:scrollPosition];
}

-(void)str_deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    TLog(@"");
    [self deselectItemAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath] animated:animated];
}

- (void)str_setDataSource:(id<UICollectionViewDataSource>)dataSource {
    TLog(@"");
    [[self str_ensureGenerator] setOriginalDataSource:dataSource gridlikeView:self];
}

- (void)str_setDelegate:(id<UICollectionViewDelegate>)delegate {
    TLog(@"");
    [[self str_ensureGenerator] setOriginalDelegate:delegate gridlikeView:self];
}

- (id<UICollectionViewDelegate>)str_delegate {
    TLog(@"");
    return [[self str_ensureGenerator] originalDelegate];
}

- (id<UICollectionViewDataSource>)str_dataSource {
    TLog(@"");
    return [[self str_ensureGenerator] originalDataSource];
}

#pragma mark - Private

- (STRGridlikeViewAdGenerator *)str_ensureGenerator {
    STRGridlikeViewAdGenerator *adGenerator = objc_getAssociatedObject(self, STRGridlikeViewAdGeneratorKey);
    if (!adGenerator) {
        [NSException raise:@"STRCollectionViewApiImproperSetup" format:@"Called %@ on a collectionview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInCollectionView:adCellReuseIdentifier:placementKey:presentingViewController:adSize:adSection:customProperties:))];
    }
    return adGenerator;
}

- (STRAdPlacementAdjuster *)str_ensureAdjuster {

    return [self str_ensureGenerator].adjuster;
}


@end
