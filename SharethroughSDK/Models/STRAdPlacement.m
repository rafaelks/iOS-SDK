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
             adIndex:(NSInteger)adIndex
        isDirectSold:(BOOL)directSold
    customProperties:(NSDictionary *)customProperties
{
    if (placementKey == nil || [placementKey length] < 8) {
        [NSException raise:@"Invalid placementKey" format:@"placementKey of %@ is invalid. Must not be nil or less than 8 characters.", placementKey];
    }

    _adView = adView;
    _placementKey = placementKey;
    _presentingViewController = presentingViewController;
    _adIndex = adIndex;
    _delegate = delegate;
    _isDirectSold = directSold;
    _customProperties = customProperties;
    
    return self;
}

@end

@implementation STRAdPlacementInfiniteScrollFields

@end