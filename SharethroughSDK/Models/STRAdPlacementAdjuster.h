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
- (NSInteger)numberOfAdsInSection:(NSInteger)section;

- (void)didInsertRowAtTrueIndexPath:(NSIndexPath *)indexPath;

@end
