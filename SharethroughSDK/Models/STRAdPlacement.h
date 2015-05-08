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
                  isDirectSold:(BOOL)directSold
                       DFPPath:(NSString *)DFPPath
                   DFPDeferred:(STRDeferred *)deferred;

@property (strong, nonatomic) UIView<STRAdView> *adView;
@property (strong, nonatomic) NSString *placementKey;
@property (strong, nonatomic) UIViewController *presentingViewController;
@property (strong, nonatomic) id<STRAdViewDelegate> delegate;
@property (nonatomic, assign) NSInteger adIndex;

//Optional DFP related properties
@property (strong, nonatomic) NSString *DFPPath;
@property (strong, nonatomic) STRDeferred *DFPDeferred;
@property (nonatomic, assign) BOOL isDirectSold;

@end

@interface STRAdPlacementInfiniteScrollFields : NSObject

@property (strong, nonatomic) NSString *placementKey;
@property (assign, nonatomic) NSUInteger articlesBeforeFirstAd;
@property (assign, nonatomic) NSUInteger articlesBetweenAds;

@end