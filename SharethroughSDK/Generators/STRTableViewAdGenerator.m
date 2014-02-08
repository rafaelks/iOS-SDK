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
#import "STRTableViewDataSourceProxy.h"

const char *const STRTableViewAdGeneratorKey = "STRTableViewAdGeneratorKey";

@interface STRTableViewAdGenerator ()

@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) STRTableViewDelegateProxy *delegateProxy;
@property (nonatomic, strong) STRTableViewDataSourceProxy *dataSourceProxy;
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

- (void)placeAdInTableView:(UITableView *)tableView
     adCellReuseIdentifier:(NSString *)adCellReuseIdentifier
              placementKey:(NSString *)placementKey
  presentingViewController:(UIViewController *)presentingViewController
                  adHeight:(CGFloat)adHeight
       adStartingIndexPath:(NSIndexPath *)adStartingIndexPath {
    STRTableViewAdGenerator *oldGenerator = objc_getAssociatedObject(tableView, STRTableViewAdGeneratorKey);

    id<UITableViewDataSource> originalDataSource = tableView.dataSource;
    id<UITableViewDelegate> originalDelegate = tableView.delegate;
    if (oldGenerator) {
        originalDataSource = oldGenerator.dataSourceProxy.originalDataSource;
        originalDelegate = oldGenerator.delegateProxy.originalDelegate;
    }

    STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[self initialIndexPathForAd:tableView preferredStartingIndexPath:adStartingIndexPath]];
    self.adjuster = adjuster;

    self.dataSourceProxy = [[STRTableViewDataSourceProxy alloc] initWithOriginalDataSource:originalDataSource adjuster:adjuster adCellReuseIdentifier:adCellReuseIdentifier placementKey:placementKey presentingViewController:presentingViewController injector:self.injector];

    self.delegateProxy = [[STRTableViewDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adjuster:adjuster adHeight:adHeight];

    tableView.dataSource = self.dataSourceProxy;
    tableView.delegate = self.delegateProxy;

    [tableView reloadData];

    objc_setAssociatedObject(tableView, STRTableViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Private

- (NSIndexPath *)initialIndexPathForAd:(UITableView *)tableView preferredStartingIndexPath:(NSIndexPath *)adStartingIndexPath {
    NSInteger numberOfRowsInAdSection = [tableView numberOfRowsInSection:adStartingIndexPath.section];
    if (adStartingIndexPath.row > numberOfRowsInAdSection) {
         [NSException raise:@"STRTableViewApiImproperSetup" format:@"Provided indexPath for advertisement cell is out of bounds: %i beyond row count %i", adStartingIndexPath.row, numberOfRowsInAdSection];
    }

    if (adStartingIndexPath) {
        return adStartingIndexPath;
    }

    NSInteger adRowPosition = [tableView numberOfRowsInSection:0] < 2 ? 0 : 1;
    return [NSIndexPath indexPathForRow:adRowPosition inSection:0];
}

@end
