//
//  STRAdPlacementAdjuster.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdPlacementAdjuster.h"

@interface STRAdPlacementAdjuster ()

@property (nonatomic, strong) NSIndexPath *adIndexPath;

@end

@implementation STRAdPlacementAdjuster

+ (instancetype)adjusterWithInitialAdIndexPath:(NSIndexPath *)adIndexPath {
    STRAdPlacementAdjuster *adjuster = [self new];
    adjuster.adIndexPath = adIndexPath;
    return adjuster;
}

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath {
    return [indexPath isEqual:self.adIndexPath];
}

- (NSInteger)numberOfAdsInSection:(NSInteger)section {
    if (section == self.adIndexPath.section && self.adLoaded) {
        return 1;
    }
    return 0;
}

- (NSIndexPath *)externalIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == nil || ([self isAdAtIndexPath:indexPath] && self.adLoaded)) {
        return nil;
    }

    if (indexPath.section != self.adIndexPath.section || !self.adLoaded) {
        return indexPath;
    }

    NSInteger adjustment = indexPath.row < self.adIndexPath.row ? 0 : 1;
    return [NSIndexPath indexPathForRow:indexPath.row - adjustment inSection:indexPath.section];
}

- (NSArray *)externalIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *externalIndexPaths = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *indexPath in indexPaths) {
        NSIndexPath *externalIndexPath = [self externalIndexPath:indexPath];
        if (externalIndexPath) {
            [externalIndexPaths addObject:externalIndexPath];
        }
    }

    return externalIndexPaths;
}

- (NSIndexPath *)trueIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == nil) {
        return nil;
    }

    if (indexPath.section != self.adIndexPath.section || !self.adLoaded) {
        return indexPath;
    }
    NSInteger adjustment = indexPath.row < self.adIndexPath.row ? 0 : 1;
    return [NSIndexPath indexPathForRow:indexPath.row + adjustment inSection:indexPath.section];
}

- (NSArray *)trueIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *trueIndexPaths = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *indexPath in indexPaths) {
        [trueIndexPaths addObject:[self trueIndexPath:indexPath]];
    }

    return trueIndexPaths;
}

- (NSArray *)willInsertRowsAtExternalIndexPaths:(NSArray *)indexPaths {
    NSArray *sortedIndexPaths = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
        return [obj1 compare:obj2];
    }];

    for (NSIndexPath *path in sortedIndexPaths) {
        if (path.row <= self.adIndexPath.row && path.section == self.adIndexPath.section) {
            self.adIndexPath = [NSIndexPath indexPathForRow:(self.adIndexPath.row + 1)
                                                  inSection:self.adIndexPath.section];
        }
    }

    return [self trueIndexPaths:indexPaths];
}

- (NSArray *)willDeleteRowsAtExternalIndexPaths:(NSArray *)indexPaths {
    NSInteger numberOfRowsBeforeAd = 0;
    for (NSIndexPath *path in indexPaths) {
        if (path.row < self.adIndexPath.row && path.section == self.adIndexPath.section) {
            numberOfRowsBeforeAd--;
        }
    }

    NSArray *preDeletionTrueIndexPaths = [self trueIndexPaths:indexPaths];
    self.adIndexPath = [NSIndexPath indexPathForRow:(self.adIndexPath.row + numberOfRowsBeforeAd)
                                          inSection:self.adIndexPath.section];
    return preDeletionTrueIndexPaths;
}

- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath {
    NSArray *deleteIndexPaths = [self willDeleteRowsAtExternalIndexPaths:@[indexPath]];
    NSArray *insertIndexPaths = [self willInsertRowsAtExternalIndexPaths:@[newIndexPath]];

    return @[[deleteIndexPaths firstObject], [insertIndexPaths firstObject]];
}

- (void)willInsertSections:(NSIndexSet *)sections {
    NSInteger section = self.adIndexPath.section + [self numberOfSectionsChangingWithAdSection:sections];
    self.adIndexPath = [NSIndexPath indexPathForRow:self.adIndexPath.row inSection:section];
}

- (void)willDeleteSections:(NSIndexSet *)sections {
    if ([sections containsIndex:self.adIndexPath.section]) {
        self.adIndexPath = [NSIndexPath indexPathForRow:-1 inSection:-1];
        return;
    }

    NSInteger section = self.adIndexPath.section - [self numberOfSectionsChangingWithAdSection:sections];
    self.adIndexPath = [NSIndexPath indexPathForRow:self.adIndexPath.row inSection:section];
}

- (void)willMoveSection:(NSInteger)section toSection:(NSInteger)newSection {
    if (section == self.adIndexPath.section) {
        self.adIndexPath = [NSIndexPath indexPathForRow:self.adIndexPath.row inSection:newSection];
        return;
    }

    [self willDeleteSections:[NSIndexSet indexSetWithIndex:section]];
    [self willInsertSections:[NSIndexSet indexSetWithIndex:newSection]];
}

- (void)willReloadAdIndexPathTo:(NSIndexPath *)indexPath {
    self.adIndexPath = indexPath;
}

#pragma mark - Private

- (NSInteger)numberOfSectionsChangingWithAdSection:(NSIndexSet *)sections {
    if (self.adIndexPath.section == -1) {
        return 0;
    }

    NSRange sectionsBeforeAd = NSMakeRange(0, self.adIndexPath.section + 1);
    return [sections countOfIndexesInRange:sectionsBeforeAd];
}

@end
