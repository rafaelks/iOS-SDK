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
#import "STRTableViewAdGenerator.h"

extern const char *const STRTableViewAdGeneratorKey;

@implementation UITableView (STR)

- (void)str_insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation {
    NSArray *indexPathsForInsertion = [[self str_ensureAdjuster] willInsertRowsAtExternalIndexPaths:indexPaths];
    [self insertRowsAtIndexPaths:indexPathsForInsertion withRowAnimation:rowAnimation];
}


- (void)str_deleteRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation {
    NSArray *indexPathsForDeletion = [[self str_ensureAdjuster] willDeleteRowsAtExternalIndexPaths:indexPaths];
    [self deleteRowsAtIndexPaths:indexPathsForDeletion withRowAnimation:rowAnimation];
}

- (void)str_moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    NSArray *indexPaths = [[self str_ensureAdjuster] willMoveRowAtExternalIndexPath:indexPath toExternalIndexPath:newIndexPath];
    [self moveRowAtIndexPath:[indexPaths firstObject] toIndexPath:[indexPaths lastObject]];
}

- (void)str_insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [[self str_ensureAdjuster] willInsertSections:sections];
    [self insertSections:sections withRowAnimation:animation];
}

- (void)str_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [[self str_ensureAdjuster] willDeleteSections:sections];
    [self deleteSections:sections withRowAnimation:animation];
}

- (void)str_moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    [[self str_ensureAdjuster] willMoveSection:section toSection:newSection];
    [self moveSection:section toSection:newSection];
}

- (UITableViewCell *)str_cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self cellForRowAtIndexPath:[[self str_ensureAdjuster] trueIndexPath:indexPath]];
}

- (NSIndexPath *)str_indexPathForCell:(UITableViewCell *)cell {
    NSIndexPath *trueIndexPath = [self indexPathForCell:cell];
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];

    if ([adjuster isAdAtIndexPath:trueIndexPath]) {
        return nil;
    }

    return [adjuster externalIndexPath:trueIndexPath];
}

- (NSIndexPath *)str_indexPathForRowAtPoint:(CGPoint)point {
    NSIndexPath *trueIndexPath = [self indexPathForRowAtPoint:point];
    STRAdPlacementAdjuster  *adjuster = [self str_ensureAdjuster];

    if ([adjuster isAdAtIndexPath:trueIndexPath]) {
        return nil;
    }

    return [adjuster externalIndexPath:trueIndexPath];
}

- (NSArray *)str_indexPathsForRowsInRect:(CGRect)rect {
    NSMutableArray *indexPathsWithoutAds = [NSMutableArray new];
    STRAdPlacementAdjuster  *adjuster = [self str_ensureAdjuster];

    for (NSIndexPath *indexPath in [self indexPathsForRowsInRect:rect]) {
        if (![adjuster isAdAtIndexPath:indexPath]) {
            [indexPathsWithoutAds addObject:[adjuster externalIndexPath:indexPath]];
        }
    }

    return indexPathsWithoutAds;
}

- (NSArray *)str_visibleCellsWithoutAds {
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
    NSMutableArray *indexPathsWithoutAds = [NSMutableArray new];
    STRAdPlacementAdjuster  *adjuster = [self str_ensureAdjuster];

    for (NSIndexPath *indexPath in [self indexPathsForVisibleRows]) {
        if (![adjuster isAdAtIndexPath:indexPath]) {
            [indexPathsWithoutAds addObject:[adjuster externalIndexPath:indexPath]];
        }
    }

    return indexPathsWithoutAds;
}

- (CGRect)str_rectForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self rectForRowAtIndexPath:[[self str_ensureAdjuster] trueIndexPath:indexPath]];
}

#pragma mark - Private

- (STRAdPlacementAdjuster *)str_ensureAdjuster {
    STRTableViewAdGenerator *adGenerator = objc_getAssociatedObject(self, STRTableViewAdGeneratorKey);
    if (!adGenerator) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Called %@ on a tableview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:))];
    }

    return adGenerator.adjuster;
}

@end
