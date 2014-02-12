//
//  STRCollectionViewAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const char * const STRCollectionViewAdGeneratorKey;

@class STRInjector, STRAdPlacementAdjuster, STRIndexPathDelegateProxy;

@interface STRCollectionViewAdGenerator : NSObject

@property (nonatomic, strong, readonly) STRAdPlacementAdjuster *adjuster;

- (id)initWithInjector:(STRInjector *)injector;

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
             adInitialIndexPath:(NSIndexPath *)adInitialIndexPath;

- (NSIndexPath *)initialIndexPathForAd:(UICollectionView *)collectionView
            preferredStartingIndexPath:(NSIndexPath *)adStartingIndexPath;

- (id<UICollectionViewDataSource>)originalDataSource;
- (void)setOriginalDelegate:(id<UICollectionViewDelegate>)newOriginalDelegate
             collectionView:(UICollectionView *)collectionView;

- (id<UICollectionViewDelegate>)originalDelegate;
- (void)setOriginalDataSource:(id<UICollectionViewDataSource>)originalDataSource
               collectionView:(UICollectionView *)collectionView;

@end
