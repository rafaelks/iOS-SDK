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

@interface STRAdPlacementAdjuster ()

@property (nonatomic) NSInteger numberOfAdSpotsAvailable;

@property (nonatomic) NSInteger numberOfAdsInSection;
@property (strong, nonatomic) STRAdCache *adCache;

@end

@implementation STRAdPlacementAdjuster

+ (instancetype)adjusterInSection:(NSInteger)section
            articlesBeforeFirstAd:(NSInteger)articlesBeforeFirstAd
               articlesBetweenAds:(NSInteger)articlesBetweenAds
                     placementKey:(NSString *)placementKey
                          adCache:(STRAdCache *)adCache {
    STRAdPlacementAdjuster *adjuster = [self new];
    adjuster.adSection = section;
    if (articlesBeforeFirstAd < 0) {
        [NSException raise:@"Articles Before First Ad Must Be Greather or Equal to 0" format:@""];
    }
    adjuster.articlesBeforeFirstAd = articlesBeforeFirstAd;
    if(articlesBetweenAds <= 0) {
        [NSException raise:@"Articles Between Ads Must Be Greater than 0" format:@""];
    }
    adjuster.articlesBetweenAds = articlesBetweenAds;
    adjuster.placementKey = placementKey;
    adjuster.adCache = adCache;
    return adjuster;
}

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath {
    if ([self shouldAdBeAtIndexPath:indexPath]) {
        STRAdPlacement *placement = [STRAdPlacement new];
        placement.placementKey = self.placementKey;
        placement.adIndex = indexPath.row;
        return [self.adCache isAdAvailableForPlacement:placement];
    }
    return NO;
}

- (NSInteger)numberOfAdsInSection:(NSInteger)section givenNumberOfRows:(NSInteger)contentRows {
    NSInteger nAdsAssignedAndAvailable = [self.adCache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:self.placementKey];
    if (section == self.adSection && nAdsAssignedAndAvailable > 0) {
        self.numberOfAdSpotsAvailable = 0;
        if (contentRows < self.articlesBeforeFirstAd) {
            return 0;
        } else {
            self.numberOfAdSpotsAvailable = 1 + (contentRows - self.articlesBeforeFirstAd) / (self.articlesBetweenAds);
            self.numberOfAdsInSection = MIN(self.numberOfAdSpotsAvailable, nAdsAssignedAndAvailable);
            return self.numberOfAdsInSection;
        }
    }
    return 0;
}

- (NSIndexPath *)indexPathWithoutAds:(NSIndexPath *)indexPath {
    return [self adjustedIndexPath:indexPath includingAds:NO];
}

- (NSArray *)indexPathsWithoutAds:(NSArray *)indexPaths {
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
    return [self adjustedIndexPath:indexPath includingAds:YES];
}

- (NSArray *)indexPathsIncludingAds:(NSArray *)indexPaths {
    NSMutableArray *trueIndexPaths = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *indexPath in indexPaths) {
        [trueIndexPaths addObject:[self indexPathIncludingAds:indexPath]];
    }

    return trueIndexPaths;
}

- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath {
    NSArray *deleteIndexPaths = [self indexPathsIncludingAds:@[indexPath]];
    NSArray *insertIndexPaths = [self indexPathsIncludingAds:@[newIndexPath]];

    return @[[deleteIndexPaths firstObject], [insertIndexPaths firstObject]];
}

- (void)willInsertSections:(NSIndexSet *)sections {
    self.adSection += [self numberOfSectionsChangingWithAdSection:sections];
}

- (void)willDeleteSections:(NSIndexSet *)sections {
    if ([sections containsIndex:self.adSection]) {
        self.adSection = -1;
        return;
    }

    self.adSection -= [self numberOfSectionsChangingWithAdSection:sections];
}

- (void)willMoveSection:(NSInteger)section toSection:(NSInteger)newSection {
    if (section == self.adSection) {
        self.adSection = newSection;
        return;
    }

    [self willDeleteSections:[NSIndexSet indexSetWithIndex:section]];
    [self willInsertSections:[NSIndexSet indexSetWithIndex:newSection]];
}

- (NSInteger)getLastCalculatedNumberOfAdsInSection:(NSInteger)section {
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

    if (indexPath.section != self.adSection){// || !self.adLoaded) { //Consider adding this back in as an optimization
        return indexPath;
    }

    NSInteger adjustment = 0;
    if ((indexPath.row - self.articlesBeforeFirstAd) >= 0) {
//        adjustment = 1 + (indexPath.row - self.articlesBeforeFirstAd) / (self.articlesBetweenAds);
        NSArray *assignedIndices = [self.adCache assignedAdIndixesForPlacementKey:self.placementKey];
        for (NSNumber *index in assignedIndices) {
            if ([index integerValue] <= indexPath.row) {
                adjustment++;
            }
        }
    }
    NSInteger adjustedRow = includeAds ? indexPath.row + adjustment : indexPath.row - adjustment;
    return [NSIndexPath indexPathForRow:adjustedRow inSection:indexPath.section];
}

@end
