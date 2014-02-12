//
//  STRCollectionViewDataSourceProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/12/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRCollectionViewDataSourceProxy.h"
#import "STRAdPlacementAdjuster.h"
#import "STRAdView.h"
#import "STRAdGenerator.h"
#import "STRInjector.h"

@interface STRCollectionViewDataSourceProxy ()

@property (nonatomic, weak, readwrite) id<UICollectionViewDataSource> originalDataSource;
@property (strong, nonatomic, readwrite) STRAdPlacementAdjuster *adjuster;
@property (copy, nonatomic, readwrite) NSString *adCellReuseIdentifier;
@property (copy, nonatomic, readwrite) NSString *placementKey;
@property (weak, nonatomic, readwrite) UIViewController *presentingViewController;
@property (weak, nonatomic, readwrite) STRInjector *injector;
@end

@implementation STRCollectionViewDataSourceProxy
- (id)initWithOriginalDataSource:(id<UICollectionViewDataSource>)originalDataSource
                          adjuster:(STRAdPlacementAdjuster *)adjuster
             adCellReuseIdentifier:(NSString *)reuseIdentifier
                      placementKey:(NSString *)placementKey
          presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.originalDataSource = originalDataSource;
        self.adjuster = adjuster;
        self.adCellReuseIdentifier = reuseIdentifier;
        self.placementKey = placementKey;
        self.presentingViewController = presentingViewController;
        self.injector = injector;
    }

    return self;
}

- (id)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)copyWithNewDataSource:(id<UICollectionViewDataSource>)newDataSource {
    return [[STRCollectionViewDataSourceProxy alloc] initWithOriginalDataSource:newDataSource
                                                                adjuster:self.adjuster adCellReuseIdentifier:self.adCellReuseIdentifier
                                                            placementKey:self.placementKey presentingViewController:self.presentingViewController
                                                                injector:self.injector];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.originalDataSource collectionView:collectionView numberOfItemsInSection:section] + [self.adjuster numberOfAdsInSection:section];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForCollectionView:collectionView atIndexPath:indexPath];
    }

    NSIndexPath *externalIndexPath = [self.adjuster externalIndexPath:indexPath];
    return [self.originalDataSource collectionView:collectionView cellForItemAtIndexPath:externalIndexPath];
}


#pragma mark - Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [[self class] instancesRespondToSelector:aSelector] || [self.originalDataSource respondsToSelector:
                                                                   aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDataSource respondsToSelector:aSelector]) {
        return self.originalDataSource;
    }

    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - Private

- (UICollectionViewCell *)adCellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell<STRAdView> *adCell = [collectionView dequeueReusableCellWithReuseIdentifier:self.adCellReuseIdentifier forIndexPath:indexPath];

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    [adGenerator placeAdInView:adCell placementKey:self.placementKey presentingViewController:self.presentingViewController delegate:nil];

    return adCell;
}
@end
