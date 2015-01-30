//
//  STRGridlikeViewAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SharethroughSDK, STRInjector, STRAdPlacementAdjuster, STRGridlikeViewDataSourceProxy;

@interface STRGridlikeViewAdGenerator : NSObject

@property (nonatomic, strong, readonly) STRAdPlacementAdjuster *adjuster;

- (id)initWithInjector:(STRInjector *)injector;

- (void)placeAdInGridlikeView:(id)gridlikeView
              dataSourceProxy:(STRGridlikeViewDataSourceProxy *)dataSourceProxy
        adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                 placementKey:(NSString *)placementKey
     presentingViewController:(UIViewController *)presentingViewController
                       adSize:(CGSize)adSize
        articlesBeforeFirstAd:(NSUInteger)articlesBeforeFirstAd
           articlesBetweenAds:(NSUInteger)articlesBetweenAds
                    adSection:(NSInteger)adSection;

- (id)originalDelegate;
- (void)setOriginalDelegate:(id)newOriginalDelegate
               gridlikeView:(id)gridlikeView;

- (id)originalDataSource;
- (void)setOriginalDataSource:(id)newOriginalDataSource
                 gridlikeView:(id)gridlikeView;

@end
