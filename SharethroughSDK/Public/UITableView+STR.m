//
//  UITableView+STR.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/3/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "UITableView+STR.h"
#import <objc/runtime.h>
#import "STRAdPlacementAdjuster.h"
#import "STRTableViewAdGenerator.h"

extern const char *const kTableViewAdGeneratorKey;

@implementation UITableView (STR)

- (void)str_insertRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation {
    NSArray *indexPathsForInsertion = [[self str_ensureAdjuster] willInsertRowsAtExternalIndexPaths:indexPaths];
    [self insertRowsAtIndexPaths:indexPathsForInsertion withRowAnimation:rowAnimation];
}


- (void)str_deleteRowsAtIndexPaths:(NSArray *)indexPaths withAnimation:(UITableViewRowAnimation)rowAnimation {
    NSArray *indexPathsForDeletion = [[self str_ensureAdjuster] willDeleteRowsAtExternalIndexPaths:indexPaths];
    [self deleteRowsAtIndexPaths:indexPathsForDeletion withRowAnimation:rowAnimation];
}

- (STRAdPlacementAdjuster *)str_ensureAdjuster {
    STRTableViewAdGenerator *adGenerator = objc_getAssociatedObject(self, kTableViewAdGeneratorKey);
    if (!adGenerator) {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Called %@ on a tableview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:))];
    }

    return adGenerator.adjuster;
}

@end
