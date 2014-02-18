//
//  STRIndexPathDelegateProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster;

@interface STRIndexPathDelegateProxy : NSObject<UITableViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic, readonly) id originalDelegate;
@property (strong, nonatomic, readonly) STRAdPlacementAdjuster *adPlacementAdjuster;
@property (assign, nonatomic, readonly) CGSize adSize;

- (id)initWithOriginalDelegate:(id)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster adSize:(CGSize)adSize;

- (instancetype)copyWithNewDelegate:(id)newDelegate;

@end
