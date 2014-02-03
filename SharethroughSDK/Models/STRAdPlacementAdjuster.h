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
- (NSIndexPath *)adjustedIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)unadjustedIndexPath:(NSIndexPath *)indexPath;

- (void)didInsertRowAtIndexPath:(NSIndexPath *)indexPath;

@end
