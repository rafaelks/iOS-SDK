//
//  STRTableViewDataSource.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRTableViewDataSource : NSObject<UITableViewDataSource>

@property (nonatomic, copy) NSArray *rowsForEachSection;

@end
