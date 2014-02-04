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
    STRTableViewAdGenerator *adGenerator = objc_getAssociatedObject(self, kTableViewAdGeneratorKey);

    if (adGenerator) {
        NSArray *sortedIndexPaths = [indexPaths sortedArrayUsingComparator:^NSComparisonResult(NSIndexPath *obj1, NSIndexPath *obj2) {
            return [@(obj1.row) compare:@(obj2.row)];
        }];
        
        NSMutableArray *trueIndexPaths = [NSMutableArray new];
        for (NSIndexPath *path in sortedIndexPaths) {
            NSIndexPath *trueIndexPath = [adGenerator.adjuster trueIndexPath:path];
            [trueIndexPaths addObject:trueIndexPath];
            [adGenerator.adjuster didInsertRowAtTrueIndexPath:trueIndexPath];
        }

        [self insertRowsAtIndexPaths:trueIndexPaths withRowAnimation:rowAnimation];
    } else {
        [NSException raise:@"STRTableViewApiImproperSetup" format:@"Called %@ on a tableview that was not setup through SharethroughSDK %@", NSStringFromSelector(_cmd), NSStringFromSelector(@selector(placeAdInTableView:adCellReuseIdentifier:placementKey:presentingViewController:adHeight:))];
    }
}

@end
