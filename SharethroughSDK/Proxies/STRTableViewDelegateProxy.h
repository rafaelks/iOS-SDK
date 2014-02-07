//
//  STRTableViewDelegateProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster;

@interface STRTableViewDelegateProxy : NSObject<UITableViewDelegate, UICollectionViewDelegate>

@property (weak, nonatomic, readonly) id originalDelegate;

- (id)initWithOriginalDelegate:(id<UITableViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster adHeight:(CGFloat)adHeight;
- (id)initWithOriginalDelegate:(id<UICollectionViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster;
@end
