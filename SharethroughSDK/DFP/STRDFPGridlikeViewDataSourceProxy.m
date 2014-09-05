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
#import "STRAdGenerator.h"
#import "STRInjector.h"
#import "STRAdPlacement.h"
#import "STRPromise.h"

@interface STRDFPGridlikeViewDataSourceProxy ()

@property (weak, nonatomic) id gridlikeView;

@end

@implementation STRDFPGridlikeViewDataSourceProxy

- (void)prefetchAdForGridLikeView:(id)gridlikeView {
    NSLog(@"%@", NSStringFromClass([self class]));

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

@end
