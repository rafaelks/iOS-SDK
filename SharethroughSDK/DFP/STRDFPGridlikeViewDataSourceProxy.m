//
//  STRDFPGridlikeViewDataSourceProxyProtocol.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 9/4/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRDFPGridlikeViewDataSourceProxy.h"

#import "STRAdView.h"
#import "STRAdPlacementAdjuster.h"
#import "STRDFPAdGenerator.h"
#import "STRInjector.h"
#import "STRAdPlacement.h"
#import "STRPromise.h"
#import "STRLogging.h"

@interface STRDFPGridlikeViewDataSourceProxy ()

@property (weak, nonatomic) id gridlikeView;

@end

@implementation STRDFPGridlikeViewDataSourceProxy

- (instancetype)copyWithNewDataSource:(id)newDataSource {
    STRDFPGridlikeViewDataSourceProxy *copy = [[[self class] alloc] initWithAdCellReuseIdentifier:self.adCellReuseIdentifier
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
    if ([gridlikeView isKindOfClass:[UITableView class]] || [gridlikeView isKindOfClass:[UICollectionView class]]) {

        STRDeferred *deferred = [STRDeferred defer];

        STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:nil
                                                                PlacementKey:self.placementKey
                                                    presentingViewController:self.gridlikeView
                                                                    delegate:nil
                                                                     adIndex:index
                                                                isDirectSold:YES
                                                                     DFPPath:nil
                                                                 DFPDeferred:deferred];

        [deferred.promise then:^id(id value) {
            [self.gridlikeView reloadData];
            return self.adjuster;
        } error:^id(NSError *error) {
            return self.adjuster;
        }];

        STRDFPAdGenerator *adGenerator = [self.injector getInstance:[STRDFPAdGenerator class]];

        [adGenerator placeAdInPlacement:adPlacement];
    }
}

- (UITableViewCell *)adCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    TLog(@"");
    UITableViewCell<STRAdView> *adCell = [tableView dequeueReusableCellWithIdentifier:self.adCellReuseIdentifier];
    if (!adCell) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib before providing to SharethroughSDK.", self.adCellReuseIdentifier];
    }

    if (![adCell conformsToProtocol:@protocol(STRAdView)]) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Bad reuse identifier provided: \"%@\". Reuse identifier needs to be registered to a class or a nib that conforms to the STRAdView protocol.", self.adCellReuseIdentifier];
    }

    STRDFPAdGenerator *adGenerator = [self.injector getInstance:[STRDFPAdGenerator class]];
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:adCell
                                                            PlacementKey:self.placementKey
                                                presentingViewController:self.presentingViewController
                                                                delegate:nil
                                                                 adIndex:indexPath.row
                                                            isDirectSold:YES
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

    STRDFPAdGenerator *adGenerator = [self.injector getInstance:[STRDFPAdGenerator class]];
    STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:adCell
                                                            PlacementKey:self.placementKey
                                                presentingViewController:self.presentingViewController
                                                                delegate:nil
                                                                 adIndex:indexPath.row
                                                            isDirectSold:YES
                                                                 DFPPath:nil
                                                             DFPDeferred:nil];

    [adGenerator placeAdInPlacement:adPlacement];
    return adCell;
}
@end
