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

- (id)initWithAdView:(UIView<STRAdView> *)adView
        PlacementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
            delegate:(id<STRAdViewDelegate>)delegate
             DFPPath:(NSString *)DFPPath
         DFPDeferred:(STRDeferred *)deferred
{
    _adView = adView;
    _placementKey = placementKey;
    _DFPPath = DFPPath;
    _presentingViewController = presentingViewController;
    _delegate = delegate;
    _DFPDeferred = deferred;
    
    return self;
}

@end