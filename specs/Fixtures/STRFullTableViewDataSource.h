//
//  STRFullTableViewDataSourceFixture.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRTableViewDataSource.h"

@interface STRFullTableViewDataSource : STRTableViewDataSource<UITableViewDataSource>

@property (nonatomic, assign) NSInteger numberOfSections;
@property (nonatomic, assign) NSInteger rowsInEachSection;

@end
