//
//  STRCollectionViewDataSource.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRCollectionViewDataSource.h"
#import "UICollectionView+STR.h"

@implementation STRCollectionViewDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.itemsForEachSection = @[@2];
    }

    return self;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.itemsForEachSection[section] integerValue];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView str_dequeueReusableCellWithReuseIdentifier:@"contentCell" forIndexPath:indexPath];

    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"item: %d, section: %d", indexPath.item, indexPath.section];
    [cell.contentView addSubview:label];

    return cell;
}

@end
