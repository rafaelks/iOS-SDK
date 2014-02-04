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

+ (instancetype)adjusterWithInitialTableView:(UITableView *)tableView {
    STRAdPlacementAdjuster *adjuster = [self new];
    adjuster.adIndexPath = [adjuster initialRowForAd:tableView];
    return adjuster;
}

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath {
    return [indexPath isEqual:self.adIndexPath];
}

- (NSInteger)numberOfAdsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return 0;
}

- (NSIndexPath *)externalIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != self.adIndexPath.section) {
        return indexPath;
    }

    if ([indexPath isEqual:self.adIndexPath]) {
        [NSException raise:@"STRInternalConsistencyError" format:@"Called %@ for an indexPath that is the same as an ad's index path: %@", NSStringFromSelector(_cmd), indexPath];
    }

    NSInteger adjustment = indexPath.row < self.adIndexPath.row ? 0 : 1;
    return [NSIndexPath indexPathForRow:indexPath.row - adjustment inSection:indexPath.section];
}

- (NSIndexPath *)trueIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != self.adIndexPath.section) {
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

- (NSIndexPath *)initialRowForAd:(UITableView *)tableView {
    NSInteger adRowPosition = 0;
    adRowPosition = [tableView numberOfRowsInSection:0] < 2 ? 0 : 1;

    return [NSIndexPath indexPathForRow:adRowPosition inSection:0];
}

- (NSArray *)willInsertRowsAtExternalIndexPaths:(NSArray *)indexPaths {
    NSInteger numberOfRowsBeforeAd = 0;
    for (NSIndexPath *path in indexPaths) {
        if (path.row <= self.adIndexPath.row && path.section == self.adIndexPath.section) {
            numberOfRowsBeforeAd++;
        }
    }
    
    self.adIndexPath = [NSIndexPath indexPathForRow:(self.adIndexPath.row + numberOfRowsBeforeAd)
                                          inSection:self.adIndexPath.section];
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

@end
