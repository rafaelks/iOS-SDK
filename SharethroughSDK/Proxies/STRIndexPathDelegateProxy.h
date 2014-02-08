//
//  STRIndexPathDelegateProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster;

@interface STRIndexPathDelegateProxy : NSObject<UITableViewDelegate, UICollectionViewDelegate>

@property (weak, nonatomic, readonly) id originalDelegate;
@property (strong, nonatomic, readonly) STRAdPlacementAdjuster *adPlacementAdjuster;
@property (assign, nonatomic, readonly) CGFloat adHeight;


- (id)initWithOriginalDelegate:(id<UITableViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster adHeight:(CGFloat)adHeight;
- (id)initWithOriginalDelegate:(id<UICollectionViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster;

- (instancetype)proxyWithNewDelegate:(id)newDelegate;

@end
