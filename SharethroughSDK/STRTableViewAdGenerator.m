//
//  STRTableViewAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTableViewAdGenerator.h"
#import "SharethroughSDK.h"
#import "STRInjector.h"
#import "STRAdGenerator.h"
#import <objc/runtime.h>
#import "STRTableViewDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"

const char *const STRTableViewAdGeneratorKey = "STRTableViewAdGeneratorKey";

@interface STRTableViewAdGenerator ()<UITableViewDataSource>

@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, weak) id<UITableViewDataSource> originalDataSource;
@property (nonatomic, copy) NSString *adCellReuseIdentifier;
@property (nonatomic, copy) NSString *placementKey;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) STRTableViewDelegateProxy *proxy;
@property (nonatomic, strong) STRAdPlacementAdjuster *adjuster;

@end

@implementation STRTableViewAdGenerator

- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
    }

    return self;
}

- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight {
    self.adCellReuseIdentifier = adCellReuseIdentifier;
    self.placementKey = placementKey;
    self.presentingViewController = presentingViewController;

    self.originalDataSource = tableView.dataSource;
    tableView.dataSource = self;

    STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[self initialIndexPathForAd:tableView]];
    self.adjuster = adjuster;
    self.proxy = [[STRTableViewDelegateProxy alloc] initWithOriginalDelegate:tableView.delegate adPlacementAdjuster:adjuster adHeight:adHeight];
    tableView.delegate = self.proxy;

    objc_setAssociatedObject(tableView, STRTableViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.originalDataSource tableView:tableView numberOfRowsInSection:section] + [self.adjuster numberOfAdsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForTableView:tableView];
    }

    NSIndexPath *adjustedIndexPath = [self.adjuster externalIndexPath:indexPath];
    return [self.originalDataSource tableView:tableView cellForRowAtIndexPath:adjustedIndexPath];
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

- (UITableViewCell *)adCellForTableView:(UITableView *)tableView {
    UITableViewCell<STRAdView> *adCell = [tableView dequeueReusableCellWithIdentifier:self.adCellReuseIdentifier];
    if (!adCell) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib before providing to SharethroughSDK.", self.adCellReuseIdentifier];
    }

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
    [adGenerator placeAdInView:adCell placementKey:self.placementKey presentingViewController:self.presentingViewController];

    return adCell;
}

- (NSIndexPath *)initialIndexPathForAd:(UITableView *)tableView {
    NSInteger adRowPosition = 0;
    adRowPosition = [tableView numberOfRowsInSection:0] < 2 ? 0 : 1;

    return [NSIndexPath indexPathForRow:adRowPosition inSection:0];
}

@end
