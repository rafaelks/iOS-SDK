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

const char * const STRCollectionViewAdGeneratorKey = "STRCollectionViewAdGeneratorKey";

@interface STRCollectionViewAdGenerator ()<UICollectionViewDataSource>


@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) STRAdPlacementAdjuster *adjuster;
@property (nonatomic, weak) id<UICollectionViewDataSource> originalDataSource;
@property (nonatomic, strong) NSString *adCellReuseIdentifier;
@property (nonatomic, strong) NSString *placementKey;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong, readwrite) STRIndexPathDelegateProxy *proxy;

@end


@implementation STRCollectionViewAdGenerator
- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
    }

    return self;
}

- (void)placeAdInCollectionView:(UICollectionView *)collectionView
          adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                   placementKey:(NSString *)placementKey
       presentingViewController:(UIViewController *)presentingViewController {

    self.originalDataSource = collectionView.dataSource;
    collectionView.dataSource = self;

    STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
    self.adjuster = adjuster;
    self.adCellReuseIdentifier = adCellReuseIdentifier;
    self.placementKey = placementKey;
    self.presentingViewController = presentingViewController;
    self.proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:collectionView.delegate adPlacementAdjuster:adjuster];
    collectionView.delegate = self.proxy;

    objc_setAssociatedObject(collectionView, STRCollectionViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark <UICollectionViewDataSource>

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForCollectionView:collectionView atIndexPath:indexPath];
    }

    NSIndexPath *externalIndexPath = [self.adjuster externalIndexPath:indexPath];
    return [self.originalDataSource collectionView:collectionView cellForItemAtIndexPath:externalIndexPath];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.originalDataSource collectionView:collectionView numberOfItemsInSection:section] + [self.adjuster numberOfAdsInSection:section];
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

    return nil;
}

#pragma mark - Private

- (UICollectionViewCell *)adCellForCollectionView:(UICollectionView *)collectionView atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell<STRAdView> *adCell = [collectionView dequeueReusableCellWithReuseIdentifier:self.adCellReuseIdentifier forIndexPath:indexPath];
    if (!adCell) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib before providing to SharethroughSDK.", self.adCellReuseIdentifier];
    }

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    [adGenerator placeAdInView:adCell placementKey:self.placementKey presentingViewController:self.presentingViewController delegate:nil];

    return adCell;
}




@end
