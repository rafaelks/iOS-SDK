//
//  STRTableViewDataSourceProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTableViewDataSourceProxy.h"
#import "STRAdView.h"
#import "STRAdPlacementAdjuster.h"
#import "STRAdGenerator.h"
#import "STRInjector.h"

@interface STRTableViewDataSourceProxy ()

@property (nonatomic, weak, readwrite) id<UITableViewDataSource> originalDataSource;
@property (strong, nonatomic) STRAdPlacementAdjuster *adjuster;
@property (copy, nonatomic) NSString *adCellReuseIdentifier;
@property (copy, nonatomic) NSString *placementKey;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) STRInjector *injector;

@end

@implementation STRTableViewDataSourceProxy

- (id)initWithOriginalDataSource:(id<UITableViewDataSource>)originalDataSource
                        adjuster:(STRAdPlacementAdjuster *)adjuster
           adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
                    placementKey:(NSString *)placementKey
        presentingViewController:(UIViewController *)presentingViewController
                        injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.originalDataSource = originalDataSource;
        self.adjuster = adjuster;
        self.adCellReuseIdentifier = adCellReuseIdentifier;
        self.placementKey = placementKey;
        self.presentingViewController = presentingViewController;
        self.injector = injector;
    }

    return self;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.originalDataSource tableView:tableView numberOfRowsInSection:section] + [self.adjuster numberOfAdsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        return [self adCellForTableView:tableView];
    }

    NSIndexPath *externalIndexPath = [self.adjuster externalIndexPath:indexPath];
    return [self.originalDataSource tableView:tableView cellForRowAtIndexPath:externalIndexPath];
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

- (UITableViewCell *)adCellForTableView:(UITableView *)tableView {
    UITableViewCell<STRAdView> *adCell = [tableView dequeueReusableCellWithIdentifier:self.adCellReuseIdentifier];
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
