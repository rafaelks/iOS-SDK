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

- (NSIndexPath *)initialRowForAd:(UITableView *)tableView {
    NSInteger adRowPosition = 0;
    adRowPosition = [tableView numberOfRowsInSection:0] < 2 ? 0 : 1;

    return [NSIndexPath indexPathForRow:adRowPosition inSection:0];
}

- (void)didInsertRowAtTrueIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row <= self.adIndexPath.row && indexPath.section == self.adIndexPath.section) {
        self.adIndexPath = [NSIndexPath indexPathForRow:(self.adIndexPath.row + 1) inSection:self.adIndexPath.section];
    }
}
@end
