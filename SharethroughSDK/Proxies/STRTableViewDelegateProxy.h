//
//  STRTableViewDelegateProxy.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdPlacementAdjuster;

@interface STRTableViewDelegateProxy : NSObject<UITableViewDelegate>

@property (weak, nonatomic, readonly) id<UITableViewDelegate> originalDelegate;

- (id)initWithOriginalDelegate:(id<UITableViewDelegate>)originalDelegate adjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster adHeight:(CGFloat)adHeight;

@end
