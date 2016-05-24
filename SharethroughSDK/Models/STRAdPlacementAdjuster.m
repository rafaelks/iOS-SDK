//
//  STRAdPlacementAdjuster.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdPlacementAdjuster.h"
#import "STRAdCache.h"
#import "STRAdPlacement.h"
#import "STRLogging.h"

@interface STRAdPlacementAdjuster ()

@property (nonatomic) NSInteger numberOfAdSpotsAvailable;

@property (nonatomic) NSInteger numberOfAdsInSection;
@property (strong, nonatomic) STRAdCache *adCache;

@end

@implementation STRAdPlacementAdjuster

+ (instancetype)adjusterInSection:(NSInteger)section
                     placementKey:(NSString *)placementKey
                          adCache:(STRAdCache *)adCache {
    STRAdPlacementAdjuster *adjuster = [self new];
    adjuster.adSection = section;
    adjuster.adCache = adCache;

    STRAdPlacementInfiniteScrollFields *fields = [adjuster.adCache getInfiniteScrollFieldsForPlacement:placementKey];
    if (fields != nil) {
        adjuster.articlesBeforeFirstAd = fields.articlesBeforeFirstAd;
        adjuster.articlesBetweenAds = fields.articlesBetweenAds;
    } else {
        adjuster.articlesBetweenAds = 1;
        adjuster.articlesBeforeFirstAd = 1;
    }
    adjuster.placementKey = placementKey;
    return adjuster;
}

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath {
    TLog(@"indexPath:%@",indexPath);
    if ([self shouldAdBeAtIndexPath:indexPath]) {
        STRAdPlacement *placement = [STRAdPlacement new];
        placement.placementKey = self.placementKey;
        placement.adIndex = indexPath.row;
        return [self.adCache isAdAvailableForPlacement:placement AndInitializeAd:YES];
    }
    return NO;
}

- (NSInteger)numberOfAdsInSection:(NSInteger)section {
    TLog(@"section:%zd numberOfRows:%zd", section, self.numContentRows);
    NSInteger nAdsAssignedAndAvailable = [self.adCache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:self.placementKey];
    if (section == self.adSection && nAdsAssignedAndAvailable > 0) {
        self.numberOfAdSpotsAvailable = 0;
        if (self.numContentRows < self.articlesBeforeFirstAd) {
            return 0;
        } else {
            self.numberOfAdSpotsAvailable = 1 + (self.numContentRows - self.articlesBeforeFirstAd) / (self.articlesBetweenAds);
            self.numberOfAdsInSection = MIN(self.numberOfAdSpotsAvailable, nAdsAssignedAndAvailable);
            return self.numberOfAdsInSection;
        }
    }
    return 0;
}

- (NSIndexPath *)indexPathWithoutAds:(NSIndexPath *)indexPath {
    TLog(@"indexPath:%@",indexPath);
    if (indexPath.section != self.adSection) {
        return indexPath;
    }
    NSIndexPath *indexPathWithOutAds = [self adjustedIndexPath:indexPath includingAds:NO];
//    This broke Flixster's integration because the number of content rows was not getting updated.
//    Tried making the value atomic, but did not resolve the issue
//    if (indexPathWithOutAds.row >= self.numContentRows) {
//        TLog(@"row %lu is greater than content rows %lu", (long)indexPathWithOutAds.row, (long)self.numberOfAdsInSection);
//        indexPathWithOutAds = [NSIndexPath indexPathForRow:self.numContentRows - 1 inSection:indexPath.section];
//    }
    TLog(@"indexPathWithoutAds:%@", indexPathWithOutAds);
    return indexPathWithOutAds;
}

- (NSArray *)indexPathsWithoutAds:(NSArray *)indexPaths {
    TLog(@"indexPath:%@",indexPaths);
    NSMutableArray *externalIndexPaths = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *indexPath in indexPaths) {
        NSIndexPath *externalIndexPath = [self indexPathWithoutAds:indexPath];
        if (externalIndexPath) {
            [externalIndexPaths addObject:externalIndexPath];
        }
    }

    return externalIndexPaths;
}

- (NSIndexPath *)indexPathIncludingAds:(NSIndexPath *)indexPath {
    TLog(@"indexPath:%@",indexPath);
    if (indexPath.section != self.adSection){
        return indexPath;
    }
    return [self adjustedIndexPath:indexPath includingAds:YES];
}

- (NSArray *)indexPathsIncludingAds:(NSArray *)indexPaths {
    TLog(@"indexPath:%@",indexPaths);
    NSMutableArray *trueIndexPaths = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *indexPath in indexPaths) {
        [trueIndexPaths addObject:[self indexPathIncludingAds:indexPath]];
    }

    return trueIndexPaths;
}

- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath {
    TLog(@"indexPath:%@",indexPath);
    NSArray *deleteIndexPaths = [self indexPathsIncludingAds:@[indexPath]];
    NSArray *insertIndexPaths = [self indexPathsIncludingAds:@[newIndexPath]];

    return @[[deleteIndexPaths firstObject], [insertIndexPaths firstObject]];
}

- (void)willInsertSections:(NSIndexSet *)sections {
    TLog(@"section: %@", sections);
    self.adSection += [self numberOfSectionsChangingWithAdSection:sections];
}

- (void)willDeleteSections:(NSIndexSet *)sections {
    TLog(@"section: %@", sections);
    if ([sections containsIndex:self.adSection]) {
        self.adSection = -1;
        return;
    }

    self.adSection -= [self numberOfSectionsChangingWithAdSection:sections];
}

- (void)willMoveSection:(NSInteger)section toSection:(NSInteger)newSection {
    TLog(@"section: %zd toSection:%zd", section, newSection);
    if (section == self.adSection) {
        self.adSection = newSection;
        return;
    }

    [self willDeleteSections:[NSIndexSet indexSetWithIndex:section]];
    [self willInsertSections:[NSIndexSet indexSetWithIndex:newSection]];
}

- (NSInteger)getLastCalculatedNumberOfAdsInSection:(NSInteger)section {
    TLog(@"section: %zd", section);
    if (section == self.adSection) {
        return self.numberOfAdsInSection;
    }
    return 0;
}

#pragma mark - Private

- (NSInteger)numberOfSectionsChangingWithAdSection:(NSIndexSet *)sections {
    if (self.adSection == -1) {
        return 0;
    }

    NSRange sectionsBeforeAd = NSMakeRange(0, self.adSection + 1);
    return [sections countOfIndexesInRange:sectionsBeforeAd];
}

- (BOOL)shouldAdBeAtIndexPath:(NSIndexPath *)indexPath {
    TLog(@"indexPath:%@",indexPath);
    if (indexPath.section == self.adSection) {
        if (indexPath.row == self.articlesBeforeFirstAd){
            return YES;
        }
        if ((indexPath.row - (self.articlesBeforeFirstAd + 1)) % (self.articlesBetweenAds + 1) == self.articlesBetweenAds ) {
            return YES;
        }
    }
    return NO;
}

- (NSIndexPath *)adjustedIndexPath:(NSIndexPath *)indexPath includingAds:(BOOL)includeAds {
    if (indexPath == nil ||
        (!includeAds && [self isAdAtIndexPath:indexPath])) {
        return nil;
    }

    NSInteger adjustment = 0;
    if ((indexPath.row - self.articlesBeforeFirstAd) >= 0) {
        NSArray *assignedIndices = [self.adCache assignedAdIndixesForPlacementKey:self.placementKey];
        for (NSNumber *index in assignedIndices) {
            if ([index integerValue] <= indexPath.row) {
                adjustment++;
            }
        }
    }
    NSInteger adjustedRow = includeAds ? indexPath.row + adjustment : indexPath.row - adjustment;
    TLog(@"indexPath:%@ includeAds:%@ adjustedRow:%zd",indexPath, includeAds ? @"YES" : @"NO", adjustedRow);
    return [NSIndexPath indexPathForRow:adjustedRow inSection:indexPath.section];
}

@end
