//
//  STRAdPlacementAdjuster.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdPlacementAdjuster.h"

@interface STRAdPlacementAdjuster ()

@property (nonatomic) NSInteger numAdsCalculated;
@property (nonatomic) BOOL adLoaded;

@end

@implementation STRAdPlacementAdjuster

+ (instancetype)adjusterInSection:(NSInteger)section
            articlesBeforeFirstAd:(NSInteger)articlesBeforeFirstAd
               articlesBetweenAds:(NSInteger)articlesBetweenAds; {
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
    return adjuster;
}

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath {
    if (self.adLoaded && indexPath.section == self.adSection) {
        if (indexPath.row == self.articlesBeforeFirstAd){
            return YES;
        }
        if ((indexPath.row - (self.articlesBeforeFirstAd + 1)) % (self.articlesBetweenAds + 1) == self.articlesBetweenAds ) {
            return YES;
        }
    }
    return NO;
}

- (void)setAdLoaded:(BOOL)adLoaded {
    if (!adLoaded) {
        self.numAdsCalculated = 0;
    }
    _adLoaded = adLoaded;
}

- (NSInteger)numberOfAdsInSection:(NSInteger)section givenNumberOfRows:(NSInteger)contentRows {
    if (section == self.adSection && self.adLoaded) {
        self.numAdsCalculated = 0;
        if (contentRows < self.articlesBeforeFirstAd) {
            return 0;
        } else {
            NSInteger adRows = 1 + (contentRows - self.articlesBeforeFirstAd) / (self.articlesBetweenAds);
            self.numAdsCalculated = adRows;
            return adRows;
        }
    }
    return 0;
}

- (NSIndexPath *)externalIndexPath:(NSIndexPath *)indexPath {
    if (indexPath == nil || ([self isAdAtIndexPath:indexPath])) {
        return nil;
    }

    if (indexPath.section != self.adSection || !self.adLoaded) {
        return indexPath;
    }
    NSInteger adjustment = 0;
    if ((indexPath.row - self.articlesBeforeFirstAd) > 0) {
       adjustment = 1 + (indexPath.row - self.articlesBeforeFirstAd) / (self.articlesBetweenAds + 1);
    }
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

    if (indexPath.section != self.adSection || !self.adLoaded) {
        return indexPath;
    }
    NSInteger adjustment = 0;
    if ((indexPath.row - self.articlesBeforeFirstAd) >= 0) {
        adjustment = 1 + (indexPath.row - self.articlesBeforeFirstAd) / (self.articlesBetweenAds);
    }
    return [NSIndexPath indexPathForRow:indexPath.row + adjustment inSection:indexPath.section];
}

- (NSArray *)trueIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *trueIndexPaths = [NSMutableArray arrayWithCapacity:[indexPaths count]];
    for (NSIndexPath *indexPath in indexPaths) {
        [trueIndexPaths addObject:[self trueIndexPath:indexPath]];
    }

    return trueIndexPaths;
}

- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath {
    NSArray *deleteIndexPaths = [self trueIndexPaths:@[indexPath]];
    NSArray *insertIndexPaths = [self trueIndexPaths:@[newIndexPath]];

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
        return self.numAdsCalculated;
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

@end
