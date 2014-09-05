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

- (id)initWithPlacementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
      delegate:(id<STRAdViewDelegate>)delegate {
    
    self.placementKey = placementKey;
    self.presentingViewController = presentingViewController;
    self.delegate = delegate;
    
    return self;
}

@end
