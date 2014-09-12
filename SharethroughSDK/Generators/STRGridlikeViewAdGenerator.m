//
//  STRGridlikeViewAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRGridlikeViewAdGenerator.h"
#import "SharethroughSDK.h"
#import "STRInjector.h"
#import "STRAdGenerator.h"
#import <objc/runtime.h>
#import "STRIndexPathDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"
#import "STRGridlikeViewDataSourceProxy.h"

const char *const STRGridlikeViewAdGeneratorKey = "STRGridlikeViewAdGeneratorKey";

@interface STRGridlikeViewAdGenerator ()

@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) STRGridlikeViewDataSourceProxy *dataSourceProxy;
@property (nonatomic, strong) STRIndexPathDelegateProxy *delegateProxy;
@property (nonatomic, strong) STRAdPlacementAdjuster *adjuster;

@end

@implementation STRGridlikeViewAdGenerator

- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
    }

    return self;
}

- (void)placeAdInGridlikeView:(id)gridlikeView
              dataSourceProxy:(STRGridlikeViewDataSourceProxy *)dataSourceProxy
        adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                 placementKey:(NSString *)placementKey
     presentingViewController:(UIViewController *)presentingViewController
                       adSize:(CGSize)adSize
           adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {

    [self validateGridlikeView:gridlikeView];

    STRGridlikeViewAdGenerator *oldGenerator = objc_getAssociatedObject(gridlikeView, STRGridlikeViewAdGeneratorKey);

    id originalDataSource = [gridlikeView dataSource];
    id originalDelegate = [gridlikeView delegate];
    if (oldGenerator) {
        originalDataSource = oldGenerator.dataSourceProxy.originalDataSource;
        originalDelegate = oldGenerator.delegateProxy.originalDelegate;
    }

    STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[self initialIndexPathForAd:gridlikeView preferredStartingIndexPath:adInitialIndexPath]];
    self.adjuster = adjuster;

    //self.dataSourceProxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:adCellReuseIdentifier placementKey:placementKey presentingViewController:presentingViewController injector:self.injector];
    self.dataSourceProxy = dataSourceProxy;
    self.dataSourceProxy.adjuster = adjuster;
    self.dataSourceProxy.originalDataSource = originalDataSource;
    
    [self.dataSourceProxy prefetchAdForGridLikeView:gridlikeView];
    
    self.delegateProxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adjuster adSize:adSize];

    [gridlikeView setDataSource:self.dataSourceProxy];
    [gridlikeView setDelegate:self.delegateProxy];

    [gridlikeView reloadData];

    objc_setAssociatedObject(gridlikeView, STRGridlikeViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Properties

- (id<UITableViewDelegate>)originalDelegate {
    return self.delegateProxy.originalDelegate;
}


- (void)setOriginalDelegate:(id)newOriginalDelegate gridlikeView:(id)gridlikeView {
    self.delegateProxy = [self.delegateProxy copyWithNewDelegate:newOriginalDelegate];
    [gridlikeView setDelegate:self.delegateProxy];
}

- (id<UITableViewDataSource>)originalDataSource {
    return self.dataSourceProxy.originalDataSource;
}
    
- (void)setOriginalDataSource:(id)newOriginalDataSource gridlikeView:(id)gridlikeView {
    self.dataSourceProxy = [self.dataSourceProxy copyWithNewDataSource:newOriginalDataSource];
    [gridlikeView setDataSource:self.dataSourceProxy];
}

#pragma mark - Initial Index Path

- (NSIndexPath *)initialIndexPathForAd:(id)gridlikeView preferredStartingIndexPath:(NSIndexPath *)adStartingIndexPath {

    NSInteger numberOfCellsInAdSection = 0;
    if ([gridlikeView isKindOfClass:[UITableView class]]) {
        numberOfCellsInAdSection = [gridlikeView numberOfRowsInSection:adStartingIndexPath.section];
    } else if ([gridlikeView isKindOfClass:[UICollectionView class]]) {
        numberOfCellsInAdSection = [gridlikeView numberOfItemsInSection:adStartingIndexPath.section];
    }

    if (adStartingIndexPath.row > numberOfCellsInAdSection) {
        if (adStartingIndexPath) {
            return [NSIndexPath indexPathForRow:numberOfCellsInAdSection + 1 inSection:adStartingIndexPath.section];
        } else {
            return [NSIndexPath indexPathForRow:numberOfCellsInAdSection + 1 inSection:0];
        }
    }

    if (adStartingIndexPath) {
        return adStartingIndexPath;
    }

    NSInteger adRowPosition = numberOfCellsInAdSection < 2 ? 0 : 1;
    return [NSIndexPath indexPathForRow:adRowPosition inSection:0];
}

#pragma mark - private

- (void)validateGridlikeView:(id)gridlikeView {
    if (![gridlikeView isKindOfClass:[UITableView class]] && ![gridlikeView isKindOfClass:[UICollectionView class]]) {
        [NSException raise:@"STRGridlikeAdGeneratorError" format:@"Provided view %@ is neither a UICollectionView nor a UITableView", gridlikeView];
    }
}


@end
