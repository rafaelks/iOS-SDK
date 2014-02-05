//
//  STRCollectionViewDataSource.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRCollectionViewDataSource : NSObject <UICollectionViewDataSource>

@property (nonatomic, copy) NSArray *itemsForEachSection;

@end
