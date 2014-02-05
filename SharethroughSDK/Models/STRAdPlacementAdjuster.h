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

+ (instancetype)adjusterWithInitialTableView:(UITableView *)tableView;

- (BOOL)isAdAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)externalIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)trueIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)trueIndexPaths:(NSArray *)indexPaths;
- (NSInteger)numberOfAdsInSection:(NSInteger)section;

- (NSArray *)willInsertRowsAtExternalIndexPaths:(NSArray *)indexPaths;
- (NSArray *)willDeleteRowsAtExternalIndexPaths:(NSArray *)indexPaths;
- (NSArray *)willMoveRowAtExternalIndexPath:(NSIndexPath *)indexPath toExternalIndexPath:(NSIndexPath *)newIndexPath;

@end
