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

@interface STRGridlikeViewDataSourceProxy ()

@property (nonatomic, weak, readwrite) id originalDataSource;
@property (nonatomic, weak) id<UITableViewDataSource> originalTVDataSource;
@property (nonatomic, weak) id<UICollectionViewDataSource> originalCVDataSource;

@property (strong, nonatomic) STRAdPlacementAdjuster *adjuster;
@property (copy, nonatomic) NSString *adCellReuseIdentifier;
@property (copy, nonatomic) NSString *placementKey;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) STRInjector *injector;

@property (weak, nonatomic) id gridlikeView;
@end

@implementation STRGridlikeViewDataSourceProxy

- (id)initWithOriginalDataSource:(id)originalDataSource
                        adjuster:(STRAdPlacementAdjuster *)adjuster
           adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                    placementKey:(NSString *)placementKey
        presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.originalDataSource = [self validateAndSetDataSource:originalDataSource];
        self.adjuster = adjuster;
        self.adCellReuseIdentifier = adCellReuseIdentifier;
        self.placementKey = placementKey;
        self.presentingViewController = presentingViewController;
        self.injector = injector;
    }

    return self;
}

- (instancetype)copyWithNewDataSource:(id)newDataSource {
    return [[[self class] alloc] initWithOriginalDataSource:newDataSource
                                                   adjuster:self.adjuster
                                      adCellReuseIdentifier:self.adCellReuseIdentifier
                                               placementKey:self.placementKey
                                   presentingViewController:self.presentingViewController
                                                   injector:self.injector];
}


- (void)prefetchAdForGridLikeView:(id)gridlikeView {
    self.gridlikeView = gridlikeView;
    if ([gridlikeView isKindOfClass:[UITableView class]] || [gridlikeView isKindOfClass:[UICollectionView class]]) {
        STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
        STRPromise *adPromise = [adGenerator prefetchAdForPlacementKey:self.placementKey];
        [adPromise then:^id(id value) {
            self.adjuster.adLoaded = YES;   
            [self.gridlikeView reloadData];
            return self.adjuster;
        } error:^id(NSError *error) {
            self.adjuster.adLoaded = NO;
            return self.adjuster;
        }];
    }
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.originalTVDataSource tableView:tableView numberOfRowsInSection:section] + [self.adjuster numberOfAdsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForTableView:tableView];
    }

    NSIndexPath *externalIndexPath = [self.adjuster externalIndexPath:indexPath];
    return [self.originalTVDataSource tableView:tableView cellForRowAtIndexPath:externalIndexPath];
}

#pragma mark - <UICollectionViewDataSource>
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.originalCVDataSource collectionView:collectionView numberOfItemsInSection:section] + [self.adjuster numberOfAdsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForCollectionView:collectionView atIndexPath:indexPath];
    }

    NSIndexPath *externalIndexPath = [self.adjuster externalIndexPath:indexPath];
    return [self.originalCVDataSource collectionView:collectionView cellForItemAtIndexPath:externalIndexPath];
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

- (UITableViewCell *)adCellForTableView:(UITableView *)tableView {
    UITableViewCell<STRAdView> *adCell = [tableView dequeueReusableCellWithIdentifier:self.adCellReuseIdentifier];
    if (!adCell) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib before providing to SharethroughSDK.", self.adCellReuseIdentifier];
    }

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWith:adCell placementKey:self.placementKey presentingViewController:self.presentingViewController delegate:nil];

    [adGenerator placeAdInPlacement:adPlacement];

    return adCell;
}

- (UICollectionViewCell *)adCellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell<STRAdView> *adCell = [collectionView dequeueReusableCellWithReuseIdentifier:self.adCellReuseIdentifier forIndexPath:indexPath];

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWith:adCell placementKey:self.placementKey presentingViewController:self.presentingViewController delegate:nil];

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
