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

+ (instancetype)adjusterWithInitialIndexPath:(NSIndexPath *)indexPath {
    STRAdPlacementAdjuster *adjuster = [self new];
    adjuster.adIndexPath = indexPath;
    return adjuster;
}

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath {
    return [indexPath isEqual:self.adIndexPath];
}

- (NSIndexPath *)adjustedIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != self.adIndexPath.section) {
        return indexPath;
    }

    if ([indexPath isEqual:self.adIndexPath]) {
        [NSException raise:@"STRInternalConsistencyError" format:@"Called %@ for an indexPath that is the same as an ad's index path: %@", NSStringFromSelector(_cmd), indexPath];
    }

    NSInteger adjustment = indexPath.row < self.adIndexPath.row ? 0 : 1;
    return [NSIndexPath indexPathForRow:indexPath.row - adjustment inSection:indexPath.section];
}

- (NSIndexPath *)unadjustedIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != self.adIndexPath.section) {
        return indexPath;
    }

    NSInteger adjustment = indexPath.row < self.adIndexPath.row ? 0 : 1;
    return [NSIndexPath indexPathForRow:indexPath.row + adjustment inSection:indexPath.section];}

@end
