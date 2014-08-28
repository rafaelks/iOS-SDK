//
//  STRAdPlacement.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/27/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdPlacement.h"

@interface STRAdPlacement ()


@end

@implementation STRAdPlacement

- (id)initWith:(UIView<STRAdView> *)view
  placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
      delegate:(id<STRAdViewDelegate>)delegate {
    
    self.adView = view;
    self.placementKey = placementKey;
    self.presentingViewController = presentingViewController;
    self.delegate = delegate;
    
    return self;
}

@end
