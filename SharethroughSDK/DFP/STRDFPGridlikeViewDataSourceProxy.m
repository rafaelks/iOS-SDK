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

- (void)prefetchAdForGridLikeView:(id)gridlikeView {
    self.gridlikeView = gridlikeView;
    if ([gridlikeView isKindOfClass:[UITableView class]] || [gridlikeView isKindOfClass:[UICollectionView class]]) {

        STRDeferred *deferred = [STRDeferred defer];

        STRAdPlacement *adPlacement = [[STRAdPlacement alloc] initWithAdView:nil
                                                                PlacementKey:self.placementKey
                                                    presentingViewController:self.gridlikeView
                                                                    delegate:nil
                                                                     DFPPath:nil
                                                                 DFPDeferred:deferred];

        [deferred.promise then:^id(id value) {
            self.adjuster.adLoaded = YES;
            [self.gridlikeView reloadData];
            return self.adjuster;
        } error:^id(NSError *error) {
            self.adjuster.adLoaded = NO;
            return self.adjuster;
        }];

        STRDFPAdGenerator *adGenerator = [self.injector getInstance:[STRDFPAdGenerator class]];

        [adGenerator placeAdInPlacement:adPlacement];
    }
}

@end
