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
#import "STRAdCache.h"
#import <objc/runtime.h>
#import "STRIndexPathDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"
#import "STRGridlikeViewDataSourceProxy.h"
#import "STRLogging.h"

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
        articlesBeforeFirstAd:(NSUInteger)articlesBeforeFirstAd
           articlesBetweenAds:(NSUInteger)articlesBetweenAds
                    adSection:(NSInteger)adSection {
    TLog(@"pkey:%@", placementKey);
    [self validateGridlikeView:gridlikeView];

    STRGridlikeViewAdGenerator *oldGenerator = objc_getAssociatedObject(gridlikeView, STRGridlikeViewAdGeneratorKey);

    id originalDataSource = [gridlikeView dataSource];
    id originalDelegate = [gridlikeView delegate];
    TLog(@"pkey:%@, oldGenerator: %@, originalDS: %@, originalDelegate:%@", placementKey, oldGenerator, originalDataSource, originalDelegate);
    if (oldGenerator) {
        if (oldGenerator.dataSourceProxy && oldGenerator.dataSourceProxy.originalDataSource) {
            originalDataSource = oldGenerator.dataSourceProxy.originalDataSource;
        }
        if (oldGenerator.delegateProxy && oldGenerator.delegateProxy.originalDelegate) {
            originalDelegate = oldGenerator.delegateProxy.originalDelegate;
        }
        TLog(@"pley:%@ oldGenerator:%@ dataSource:%@, delegate:%@", placementKey, oldGenerator, originalDataSource, originalDelegate);
    }

    STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterInSection:adSection
                                                           articlesBeforeFirstAd:articlesBeforeFirstAd
                                                              articlesBetweenAds:articlesBetweenAds
                                                                    placementKey:placementKey
                                                                         adCache:[self.injector getInstance:[STRAdCache class]]];
    self.adjuster = adjuster;

    self.dataSourceProxy = dataSourceProxy;
    self.dataSourceProxy.adjuster = adjuster;
    self.dataSourceProxy.originalDataSource = originalDataSource;

    [self.dataSourceProxy prefetchAdForGridLikeView:gridlikeView atIndex:articlesBeforeFirstAd];

    self.delegateProxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adjuster adSize:adSize];

    [gridlikeView setDataSource:self.dataSourceProxy];
    [gridlikeView setDelegate:self.delegateProxy];

    [gridlikeView reloadData];

    objc_setAssociatedObject(gridlikeView, STRGridlikeViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    TLog(@"Finished setting objc assocition for pkey:%@", placementKey);
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

#pragma mark - private

- (void)validateGridlikeView:(id)gridlikeView {
    if (![gridlikeView isKindOfClass:[UITableView class]] && ![gridlikeView isKindOfClass:[UICollectionView class]]) {
        [NSException raise:@"STRGridlikeAdGeneratorError" format:@"Provided view %@ is neither a UICollectionView nor a UITableView", gridlikeView];
    }
}


@end
