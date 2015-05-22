//
//  STRGridlikeViewDataSourceProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRGridlikeViewDataSourceProxy.h"
#import "STRAdView.h"
#import "STRAdPlacementAdjuster.h"
#import "STRAdGenerator.h"
#import "STRInjector.h"
#import "STRAdPlacement.h"
#import "STRPromise.h"
#import "STRLogging.h"

@interface STRGridlikeViewDataSourceProxy ()

@property (nonatomic, weak) id<UITableViewDataSource> originalTVDataSource;
@property (nonatomic, weak) id<UICollectionViewDataSource> originalCVDataSource;

@property (copy, nonatomic) NSString *adCellReuseIdentifier;
@property (copy, nonatomic) NSString *placementKey;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) STRInjector *injector;

@property (strong, nonatomic) STRAdPlacement *placement;

@property (weak, nonatomic) id gridlikeView;
@end

@implementation STRGridlikeViewDataSourceProxy

- (id)initWithAdCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                       placementKey:(NSString *)placementKey
           presentingViewController:(UIViewController *)presentingViewController
                           injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        if (placementKey == nil || [placementKey length] < 8) {
            [NSException raise:@"Invalid placementKey" format:@"placementKey of %@ is invalid. Must not be nil or less than 8 characters.", placementKey];
        }
        self.numAdsInView = 0;
        self.adCellReuseIdentifier = adCellReuseIdentifier;
        self.placementKey = placementKey;
        self.presentingViewController = presentingViewController;
        self.injector = injector;
        self.placement = [[STRAdPlacement alloc] init];
        self.placement.placementKey = self.placementKey;
        self.placement.delegate = self;
    }

    return self;
}

- (instancetype)copyWithNewDataSource:(id)newDataSource {
    TLog(@"");
    STRGridlikeViewDataSourceProxy *copy = [[[self class] alloc] initWithAdCellReuseIdentifier:self.adCellReuseIdentifier
                                                                                     placementKey:self.placementKey
                                                                         presentingViewController:self.presentingViewController
                                                                                         injector:self.injector];
    copy.originalDataSource = newDataSource;
    copy.adjuster = self.adjuster;
    return copy;
}

- (void)prefetchAdForGridLikeView:(id)gridlikeView atIndex:(NSInteger)index {
    TLog(@"");
    self.gridlikeView = gridlikeView;
    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    STRPromise *adPromise = [adGenerator prefetchAdForPlacement:self.placement];
    [adPromise then:^id(id value) {
        TLog(@"Prefetch succeeded");
        [self.gridlikeView reloadData];
        return self.adjuster;
    } error:^id(NSError *error) {
        TLog(@"Prefetch failed");
        return self.adjuster;
    }];
}

- (void)setOriginalDataSource:(id)originalDataSource {
    _originalDataSource = [self validateAndSetDataSource:originalDataSource];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    TLog(@"");
    NSInteger numberofContentRows = [self.originalTVDataSource tableView:tableView numberOfRowsInSection:section];

    self.numAdsInView = [self.adjuster numberOfAdsInSection:section givenNumberOfRows:numberofContentRows];
    return  numberofContentRows + self.numAdsInView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForTableView:tableView atIndexPath:indexPath];
    }

    NSIndexPath *externalIndexPath = [self.adjuster indexPathWithoutAds:indexPath];
    return [self.originalTVDataSource tableView:tableView cellForRowAtIndexPath:externalIndexPath];
}

#pragma mark - <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    TLog(@"");
    NSInteger numberofContentRows =  [self.originalCVDataSource collectionView:collectionView numberOfItemsInSection:section];

    self.numAdsInView = [self.adjuster numberOfAdsInSection:section givenNumberOfRows:numberofContentRows];
    return  numberofContentRows + self.numAdsInView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForCollectionView:collectionView atIndexPath:indexPath];
    }

    NSIndexPath *externalIndexPath = [self.adjuster indexPathWithoutAds:indexPath];
    return [self.originalCVDataSource collectionView:collectionView cellForItemAtIndexPath:externalIndexPath];
}

#pragma mark - STRAdViewDelegate
- (void)adView:(id<STRAdView>)adView didFetchArticlesBeforeFirstAd:(NSInteger)articlesBeforeFirstAd andArticlesBetweenAds:(NSInteger)articlesBetweenAds forPlacementKey:(NSString *)placementKey {
    TLog(@"");
    self.adjuster.articlesBeforeFirstAd = articlesBeforeFirstAd;
    self.adjuster.articlesBetweenAds = articlesBetweenAds;
}

#pragma mark - Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [[self class] instancesRespondToSelector:aSelector]
    || [self.originalDataSource respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDataSource respondsToSelector:aSelector]) {
        return self.originalDataSource;
    }

    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - Private

- (UITableViewCell *)adCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    UITableViewCell<STRAdView> *adCell = [tableView dequeueReusableCellWithIdentifier:self.adCellReuseIdentifier];
    if (!adCell) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib before providing to SharethroughSDK.", self.adCellReuseIdentifier];
    }

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:adCell
                                                            PlacementKey:self.placementKey
                                                presentingViewController:self.presentingViewController
                                                                delegate:nil
                                                                 adIndex:indexPath.row
                                                            isDirectSold:NO
                                                                 DFPPath:nil
                                                             DFPDeferred:nil];
    [adGenerator placeAdInPlacement:adPlacement];

    return adCell;
}

- (UICollectionViewCell *)adCellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    UICollectionViewCell<STRAdView> *adCell = [collectionView dequeueReusableCellWithReuseIdentifier:self.adCellReuseIdentifier forIndexPath:indexPath];

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:adCell
                                                            PlacementKey:self.placementKey
                                                presentingViewController:self.presentingViewController
                                                                delegate:nil
                                                                 adIndex:indexPath.row
                                                            isDirectSold:NO
                                                                 DFPPath:nil
                                                             DFPDeferred:nil];

    [adGenerator placeAdInPlacement:adPlacement];
    return adCell;
}

- (id)validateAndSetDataSource:(id)originalDataSource {
    if (originalDataSource) {
        if ([originalDataSource conformsToProtocol:@protocol(UITableViewDataSource)]
            && [originalDataSource conformsToProtocol:@protocol(UICollectionViewDataSource)]) {
            self.originalTVDataSource = originalDataSource;
            self.originalCVDataSource = originalDataSource;
            return originalDataSource;
        } else if ([originalDataSource conformsToProtocol:@protocol(UITableViewDataSource)]) {
            self.originalTVDataSource = originalDataSource;
            return self.originalTVDataSource;
        } else if ([originalDataSource conformsToProtocol:@protocol(UICollectionViewDataSource)]) {
            self.originalCVDataSource = originalDataSource;
            return self.originalCVDataSource;
        } else {
            [NSException raise:@"STRGridlikeInvalidParameter" format:@"parameter %@ does not conform to <UITableViewDataSource> or <UICollectionViewDataSource>. It must conform to one of these.", originalDataSource];
        }
    }
    return nil;
}

@end
