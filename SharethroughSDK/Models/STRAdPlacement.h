//
//  STRAdPlacement.h
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/27/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STRAdView.h"
#import "STRAdViewDelegate.h"
#import "STRAdPlacementAdjuster.h"

@interface STRAdPlacement : NSObject

- (instancetype)initWithPlacementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
                delegate:(id<STRAdViewDelegate>)delegate;

@property (strong, nonatomic) UIView<STRAdView> *adView;
@property (strong, nonatomic) NSString *placementKey;
@property (strong, nonatomic) UIViewController *presentingViewController;
@property (strong, nonatomic) id<STRAdViewDelegate> delegate;
@property (strong, nonatomic) STRAdPlacementAdjuster *adjuster;

@end
