//
//  STRCollectionViewDelegateProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/6/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster;

@interface STRCollectionViewDelegateProxy : NSObject<UICollectionViewDelegate>

- (id)initWithOriginalDelegate:(id<UICollectionViewDelegate>)delegate
                    adAdjuster:(STRAdPlacementAdjuster *)adjuster;

@property (nonatomic, strong) id<UICollectionViewDelegate> originalDelegate;

@end
