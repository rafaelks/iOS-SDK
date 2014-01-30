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

@interface STRTableViewAdGenerator ()<UITableViewDataSource>

@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, weak) id<UITableViewDataSource> originalDataSource;
@property (nonatomic, copy) NSString *adCellReuseIdentifier;
@property (nonatomic, copy) NSString *placementKey;
@property (nonatomic, weak) UIViewController *presentingViewController;

@end

@implementation STRTableViewAdGenerator

- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
    }

    return self;
}

- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController {
    self.adCellReuseIdentifier = adCellReuseIdentifier;
    self.placementKey = placementKey;
    self.presentingViewController = presentingViewController;

    self.originalDataSource = tableView.dataSource;
    tableView.dataSource = self;
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.originalDataSource tableView:tableView numberOfRowsInSection:section] + (section == 0 ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowPositionOfAd = [tableView numberOfRowsInSection:0] < 2 ? 0 : 1;

    if (indexPath.row == rowPositionOfAd && indexPath.section == 0) {
        UITableViewCell<STRAdView> *adCell = [tableView dequeueReusableCellWithIdentifier:self.adCellReuseIdentifier];
        STRAdGenerator *adGenerator = [self.injector getInstance:[STRAdGenerator class]];
        [adGenerator placeAdInView:adCell placementKey:self.placementKey presentingViewController:self.presentingViewController];
        return adCell;
    }

    NSInteger adjustment = indexPath.row < rowPositionOfAd ? 0 : 1;
    NSIndexPath *adjustedIndexPath = [NSIndexPath indexPathForRow:indexPath.row - adjustment inSection:indexPath.section];
    return [self.originalDataSource tableView:tableView cellForRowAtIndexPath:adjustedIndexPath];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger originalNumberOfSections = 1;
    if ([self.originalDataSource respondsToSelector:@selector(numberOfSectionsInTableView:)]) {
        originalNumberOfSections = [self.originalDataSource numberOfSectionsInTableView:tableView];
    }
    return MAX(originalNumberOfSections, 1);
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

@end
