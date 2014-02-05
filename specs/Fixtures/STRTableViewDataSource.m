//
//  STRTableViewDataSource.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTableViewDataSource.h"

@implementation STRTableViewDataSource

- (id)init {
    self = [super init];
    if (self) {
        self.rowsForEachSection = @[@1];
    }

    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.rowsForEachSection[section] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [UITableViewCell new];
    cell.textLabel.text = [NSString stringWithFormat:@"row: %d, section: %d", indexPath.row, indexPath.section];
    return cell;
}

@end
