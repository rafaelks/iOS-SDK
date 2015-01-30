//
//  NSMutableArray+Queue.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 12/23/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (STRQueue)
- (id)dequeue;
- (void)enqueue:(id)obj;
- (id)peek;
@end
