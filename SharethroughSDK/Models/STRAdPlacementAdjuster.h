//
//  STRAdPlacementAdjuster.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRAdPlacementAdjuster : NSObject

@property (nonatomic, strong, readonly) NSIndexPath *adIndexPath;
@property (nonatomic) BOOL adLoaded;

+ (instancetype)adjusterWithInitialAdIndexPath:(NSIndexPath *)adIndexPath;

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)externalIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)externalIndexPaths:(NSArray *)indexPaths;
- (NSIndexPath *)trueIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)trueIndexPaths:(NSArray *)indexPaths;
- (NSInteger)numberOfAdsInSection:(NSInteger)section;

- (NSArray *)willInsertRowsAtExternalIndexPaths:(NSArray *)indexPaths;
- (NSArray *)willDeleteRowsAtExternalIndexPaths:(NSArray *)indexPaths;
- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath;

- (void)willInsertSections:(NSIndexSet *)sections;
- (void)willDeleteSections:(NSIndexSet *)sections;
- (void)willMoveSection:(NSInteger)section toSection:(NSInteger)newSection;
- (void)willReloadAdIndexPathTo:(NSIndexPath *)indexPath;

@end
