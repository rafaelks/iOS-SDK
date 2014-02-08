//
//  STRFullCollectionViewDataSource.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/7/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRFullCollectionViewDataSource.h"

@implementation STRFullCollectionViewDataSource

- (id) init {
    self = [super init];
    if (self) {
        self.numberOfSections = 2;
        self.itemsForEachSection = @[@1, @1];
    }

    return self;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.numberOfSections;
}
@end
