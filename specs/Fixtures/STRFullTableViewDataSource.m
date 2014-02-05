//
//  STRFullTableViewDataSourceFixture.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRFullTableViewDataSource.h"

@implementation STRFullTableViewDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.numberOfSections = 2;
        self.rowsForEachSection = @[@1, @1];
    }

    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.numberOfSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"title for footer";
}

@end
