//
//  UICollectionView+STR.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "UICollectionView+STR.h"
#import "STRAdPlacementAdjuster.h"
#import <objc/runtime.h>
#import "STRCollectionViewAdGenerator.h"

extern const char * const STRCollectionViewAdGeneratorKey;

@implementation UICollectionView (STR)

- (id)str_dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    STRAdPlacementAdjuster *adjuster = [self str_ensureAdjuster];
    NSIndexPath *trueIndexPath = [adjuster trueIndexPath:indexPath];

    return [self dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:trueIndexPath];
}


#pragma mark - Private

- (STRAdPlacementAdjuster *)str_ensureAdjuster {
    STRCollectionViewAdGenerator *adGenerator = objc_getAssociatedObject(self, STRCollectionViewAdGeneratorKey);
    if (!adGenerator) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Called %@ on a collectionview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInCollectionView:adCellReuseIdentifier:placementKey:presentingViewController:))];
    }

    return adGenerator.adjuster;
}


@end
