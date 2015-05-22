//
//  UITableView+STR.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/3/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "UITableView+STR.h"
#import <objc/runtime.h>
#import "STRAdPlacementAdjuster.h"
#import "STRGridlikeViewAdGenerator.h"
#import "STRLogging.h"

extern const char *const STRGridlikeViewAdGeneratorKey;

@implementation UITableView (STR)

- (void)str_insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation {
    TLog(@"");
    NSArray *indexPathsForInsertion = [[self str_ensureAdjuster] indexPathsIncludingAds:indexPaths];
    [self insertRowsAtIndexPaths:indexPathsForInsertion withRowAnimation:rowAnimation];
}


- (void)str_deleteRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation {
    TLog(@"");
    NSArray *indexPathsForDeletion = [[self str_ensureAdjuster] indexPathsIncludingAds:indexPaths];
    [self deleteRowsAtIndexPaths:indexPathsForDeletion withRowAnimation:rowAnimation];
}

- (void)str_moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    TLog(@"");
    NSArray *indexPaths = [[self str_ensureAdjuster] willMoveRowAtExternalIndexPath:indexPath toExternalIndexPath:newIndexPath];
    [self moveRowAtIndexPath:[indexPaths firstObject] toIndexPath:[indexPaths lastObject]];
}

- (void)str_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    TLog(@"");
    [[self str_ensureAdjuster] willInsertSections:sections];
    [self insertSections:sections withRowAnimation:animation];
}

- (void)str_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    TLog(@"");
    [[self str_ensureAdjuster] willDeleteSections:sections];
    [self deleteSections:sections withRowAnimation:animation];
}

- (void)str_moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    TLog(@"");
    [[self str_ensureAdjuster] willMoveSection:section toSection:newSection];
    [self moveSection:section toSection:newSection];
}

- (void)str_reloadData {
    TLog(@"");
    [self reloadData];
}

-(void)str_reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    TLog(@"");
    [self reloadRowsAtIndexPaths:[[self str_ensureAdjuster] indexPathsIncludingAds:indexPaths] withRowAnimation:animation];
}

- (void)str_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    TLog(@"");
    [self reloadSections:sections withRowAnimation:animation];
}

- (id<UITableViewDataSource>)str_dataSource {
    TLog(@"");
    return [[self str_ensureGenerator] originalDataSource];
}

- (void)str_setDataSource:(id<UITableViewDataSource>)dataSource {
    TLog(@"");
    [[self str_ensureGenerator] setOriginalDataSource:dataSource gridlikeView:self];
}

- (id<UITableViewDelegate>)str_delegate {
    TLog(@"");
    return [[self str_ensureGenerator] originalDelegate];
}

- (void)str_setDelegate:(id<UITableViewDelegate>)delegate {
    TLog(@"");
    [[self str_ensureGenerator] setOriginalDelegate:delegate gridlikeView:self];
}

- (UITableViewCell *)str_cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    return [self cellForRowAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath]];
}

- (NSIndexPath *)str_indexPathForCell:(UITableViewCell *)cell {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathWithoutAds:[self indexPathForCell:cell]];
}

- (NSIndexPath *)str_indexPathForRowAtPoint:(CGPoint)point {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathWithoutAds:[self indexPathForRowAtPoint:point]];
}

- (NSArray *)str_indexPathsForRowsInRect:(CGRect)rect {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathsWithoutAds:[self indexPathsForRowsInRect:rect]];
}

- (NSArray *)str_visibleCellsWithoutAds {
    TLog(@"");
    NSMutableArray *cellsWithoutAds = [NSMutableArray new];
    STRAdPlacementAdjuster  *adjuster = [self str_ensureAdjuster];

    for (UITableViewCell *cell in [self visibleCells]) {
        if (![adjuster isAdAtIndexPath:[self indexPathForCell:cell]]) {
            [cellsWithoutAds addObject:cell];
        }
    }

    return cellsWithoutAds;
}

- (NSArray *)str_indexPathsForVisibleRows {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathsWithoutAds:[self indexPathsForVisibleRows]];
}

- (CGRect)str_rectForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    return [self rectForRowAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath]];
}

- (NSInteger)str_numberOfRowsInSection:(NSInteger)section {
    TLog(@"");
    return  [self numberOfRowsInSection:section] - [[self str_ensureAdjuster] getLastCalculatedNumberOfAdsInSection:section];
}

- (NSIndexPath *)str_indexPathForSelectedRow {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathWithoutAds:[self indexPathForSelectedRow]];
}

- (NSArray *)str_indexPathsForSelectedRows {
    TLog(@"");
    return [[self str_ensureAdjuster] indexPathsWithoutAds:[self indexPathsForSelectedRows]];
}

- (void)str_selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition {
    TLog(@"");
    [self selectRowAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath] animated:animated scrollPosition:scrollPosition];
}

-(void)str_deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    TLog(@"");
    [self deselectRowAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath] animated:animated];
}

- (void)str_scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    TLog(@"");
    [self scrollToRowAtIndexPath:[[self str_ensureAdjuster] indexPathIncludingAds:indexPath] atScrollPosition:scrollPosition animated:animated];
}

#pragma mark - Private

- (STRAdPlacementAdjuster *)str_ensureAdjuster {
    return [self str_ensureGenerator].adjuster;
}

- (STRGridlikeViewAdGenerator *)str_ensureGenerator {
    STRGridlikeViewAdGenerator *adGenerator = objc_getAssociatedObject(self, STRGridlikeViewAdGeneratorKey);
    if (!adGenerator) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Called %@ on a tableview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInGridlikeView:dataSourceProxy:adCellReuseIdentifier:placementKey:presentingViewController:adSize:articlesBeforeFirstAd:articlesBetweenAds:adSection:))];
    }
    return adGenerator;
}

@end
