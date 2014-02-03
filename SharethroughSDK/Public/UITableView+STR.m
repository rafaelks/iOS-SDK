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

- (void)str_insertRowAtIndexPath:(NSIndexPath *)indexPath withAnimation:(UITableViewRowAnimation)rowAnimation {
    STRTableViewAdGenerator *adGenerator = objc_getAssociatedObject(self, kTableViewAdGeneratorKey);
    if (adGenerator) {
        NSIndexPath *unadjustedIndexPath = [adGenerator.adjuster unadjustedIndexPath:indexPath];
        [self insertRowsAtIndexPaths:@[unadjustedIndexPath] withRowAnimation:rowAnimation];
        [adGenerator.adjuster didInsertRowAtIndexPath:indexPath];
    } else {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Called %@ on a tableview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:))];
    }
}

@end
