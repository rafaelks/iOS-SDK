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
#import "STRDeferred.h"

@interface STRAdPlacement : NSObject

- (instancetype)initWithAdView:(UIView<STRAdView> *)adView
                  PlacementKey:(NSString *)placementKey
      presentingViewController:(UIViewController *)presentingViewController
                      delegate:(id<STRAdViewDelegate>)delegate
                       adIndex:(NSInteger)adIndex
              customProperties:(NSDictionary *)customProperties;

@property (strong, nonatomic) UIView<STRAdView> *adView;
@property (copy, nonatomic) NSString *placementKey;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) id<STRAdViewDelegate> delegate;
@property (nonatomic, assign) NSInteger adIndex;
@property (strong, nonatomic) NSDictionary *customProperties;

@end

@interface STRAdPlacementInfiniteScrollFields : NSObject

@property (copy, nonatomic) NSString *placementKey;
@property (assign, nonatomic) NSUInteger articlesBeforeFirstAd;
@property (assign, nonatomic) NSUInteger articlesBetweenAds;

@end