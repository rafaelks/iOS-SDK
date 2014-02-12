//
//  STRCollectionViewAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRCollectionViewAdGenerator.h"
#import "STRInjector.h"
#import <objc/runtime.h>
#import "STRAdPlacementAdjuster.h"
#import "STRAdView.h"
#import "STRAdGenerator.h"
#import "STRIndexPathDelegateProxy.h"
#import "STRCollectionViewDataSourceProxy.h"

const char * const STRCollectionViewAdGeneratorKey = "STRCollectionViewAdGeneratorKey";

@interface STRCollectionViewAdGenerator ()


@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) STRAdPlacementAdjuster *adjuster;
@property (nonatomic, strong) STRCollectionViewDataSourceProxy *dataSourceProxy;
@property (nonatomic, strong, readwrite) STRIndexPathDelegateProxy *delegateProxy;

@end

@implementation STRCollectionViewAdGenerator
- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
    }

    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController
             adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {

    self.adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[self initialIndexPathForAd:collectionView preferredStartingIndexPath:adInitialIndexPath]];

    self.dataSourceProxy = [[STRCollectionViewDataSourceProxy alloc] initWithOriginalDataSource:collectionView.dataSource
                                                                                       adjuster:self.adjuster
                                                                          adCellReuseIdentifier:adCellReuseIdentifier
                                                                                   placementKey:placementKey
                                                                       presentingViewController:presentingViewController
                                                                                       injector:self.injector];

    self.delegateProxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:collectionView.delegate adPlacementAdjuster:self.adjuster];
    
    collectionView.dataSource = self.dataSourceProxy;
    collectionView.delegate = self.delegateProxy;
    [collectionView reloadData];

    objc_setAssociatedObject(collectionView, STRCollectionViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



#pragma mark - Proxy getters
- (id<UICollectionViewDelegate>)originalDelegate {
    return self.delegateProxy.originalDelegate;
}

- (id<UICollectionViewDataSource>)originalDataSource {
    return self.dataSourceProxy.originalDataSource;
}

#pragma mark - Proxy setters

- (void)setOriginalDelegate:(id<UICollectionViewDelegate>)newOriginalDelegate collectionView:(UICollectionView *)collectionView {
    STRIndexPathDelegateProxy *newProxy = [self.delegateProxy copyWithNewDelegate:newOriginalDelegate];
    self.delegateProxy = newProxy;
    collectionView.delegate = newProxy;
}

- (void)setOriginalDataSource:(id<UICollectionViewDataSource>)newOriginalDataSource
               collectionView:(UICollectionView *)collectionView {
    self.dataSourceProxy = [self.dataSourceProxy copyWithNewDataSource:newOriginalDataSource];
    collectionView.dataSource = self.dataSourceProxy;
}

#pragma mark - Initial Index Path

- (NSIndexPath *)initialIndexPathForAd:(UICollectionView *)collectionView preferredStartingIndexPath:(NSIndexPath *)adStartingIndexPath {
    NSInteger numberOfItemsInAdSection = [collectionView numberOfItemsInSection:adStartingIndexPath.section];
    if (adStartingIndexPath.row > numberOfItemsInAdSection) {
        [NSException raise:@"STRCollectionViewApiImproperSetup" format:@"Provided indexPath for advertisement cell is out of bounds: %i beyond item count %i", adStartingIndexPath.row, numberOfItemsInAdSection];
    }

    if (adStartingIndexPath) {
        return adStartingIndexPath;
    }

    NSInteger adRowPosition = [collectionView numberOfItemsInSection:0] < 2 ? 0 : 1;
    return [NSIndexPath indexPathForRow:adRowPosition inSection:0];
}

@end
