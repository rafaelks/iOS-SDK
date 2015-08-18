//
//  STRAdPlacementAdjuster.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdCache;

@interface STRAdPlacementAdjuster : NSObject

@property (nonatomic) NSInteger adSection;
@property (nonatomic) NSInteger articlesBeforeFirstAd;
@property (nonatomic) NSInteger articlesBetweenAds;
@property (nonatomic) NSInteger numContentRows;
@property (nonatomic, strong) NSString *placementKey;

+ (instancetype)adjusterInSection:(NSInteger)section
            articlesBeforeFirstAd:(NSInteger)articlesBeforeFirstAd
               articlesBetweenAds:(NSInteger)articlesBetweenAds
                     placementKey:(NSString *)placementKey
                          adCache:(STRAdCache *)adCache;

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)numberOfAdsInSection:(NSInteger)section;

- (NSIndexPath *)indexPathWithoutAds:(NSIndexPath *)indexPath;
- (NSArray *)indexPathsWithoutAds:(NSArray *)indexPaths;
- (NSIndexPath *)indexPathIncludingAds:(NSIndexPath *)indexPath;
- (NSArray *)indexPathsIncludingAds:(NSArray *)indexPaths;
- (NSInteger)getLastCalculatedNumberOfAdsInSection:(NSInteger)section;

- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath;

- (void)willInsertSections:(NSIndexSet *)sections;
- (void)willDeleteSections:(NSIndexSet *)sections;
- (void)willMoveSection:(NSInteger)section toSection:(NSInteger)newSection;

@end
