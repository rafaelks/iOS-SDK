//
//  STRDateProvider.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRDateProvider : NSObject

- (NSDate *)now;
- (long long)millisecondsSince1970;

@end
