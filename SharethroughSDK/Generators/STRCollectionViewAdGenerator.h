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
@property (nonatomic, strong, readonly) STRIndexPathDelegateProxy *proxy;

- (id)initWithInjector:(STRInjector *)injector;
- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
            adInitialIndexPath:(NSIndexPath *)adInitialIndexPath;
- (NSIndexPath *)initialIndexPathForAd:(UICollectionView *)collectionView preferredStartingIndexPath:(NSIndexPath *)adStartingIndexPath;
@end
