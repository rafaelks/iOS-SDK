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
#import "STRIndexPathDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"
#import "STRGridlikeViewDataSourceProxy.h"

const char *const STRTableViewAdGeneratorKey = "STRTableViewAdGeneratorKey";

@interface STRTableViewAdGenerator ()

@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) STRGridlikeViewDataSourceProxy *dataSourceProxy;
@property (nonatomic, strong) STRIndexPathDelegateProxy *delegateProxy;
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
       adInitialIndexPath:(NSIndexPath *)adInitialIndexPath {
    STRTableViewAdGenerator *oldGenerator = objc_getAssociatedObject(tableView, STRTableViewAdGeneratorKey);

    id<UITableViewDataSource> originalDataSource = tableView.dataSource;
    id<UITableViewDelegate> originalDelegate = tableView.delegate;
    if (oldGenerator) {
        originalDataSource = oldGenerator.dataSourceProxy.originalDataSource;
        originalDelegate = oldGenerator.delegateProxy.originalDelegate;
    }

    STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[self initialIndexPathForAd:tableView preferredStartingIndexPath:adInitialIndexPath]];
    self.adjuster = adjuster;

    self.dataSourceProxy = [[STRGridlikeViewDataSourceProxy alloc] initWithOriginalDataSource:originalDataSource adjuster:adjuster adCellReuseIdentifier:adCellReuseIdentifier placementKey:placementKey presentingViewController:presentingViewController injector:self.injector];
    self.delegateProxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adjuster adHeight:adHeight];

    tableView.dataSource = self.dataSourceProxy;
    tableView.delegate = self.delegateProxy;

    [tableView reloadData];

    objc_setAssociatedObject(tableView, STRTableViewAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Properties

- (id<UITableViewDelegate>)originalDelegate {
    return self.delegateProxy.originalDelegate;
}


- (void)setOriginalDelegate:(id<UITableViewDelegate>)newOriginalDelegate tableView:(UITableView *)tableView {
    self.delegateProxy = [self.delegateProxy copyWithNewDelegate:newOriginalDelegate];
    tableView.delegate = self.delegateProxy;
}

- (id<UITableViewDataSource>)originalDataSource {
    return self.dataSourceProxy.originalDataSource;
}
    
- (void)setOriginalDataSource:(id<UITableViewDataSource>)newOriginalDataSource tableView:(UITableView *)tableView {
    self.dataSourceProxy = [self.dataSourceProxy copyWithNewDataSource:newOriginalDataSource];
    tableView.dataSource = self.dataSourceProxy;
}

#pragma mark - Initial Index Path

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
