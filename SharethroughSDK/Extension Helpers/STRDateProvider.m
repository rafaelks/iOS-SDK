//
//  STRDateProvider.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRDateProvider.h"

@implementation STRDateProvider

- (NSDate *)now {
    return [NSDate date];
}

- (long)millisecondsSince1970 {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

@end
