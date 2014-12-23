//
//  NSMutableArray+Queue.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 12/23/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "NSMutableArray+Queue.h"

@implementation NSMutableArray (STRQueue)

- (id) dequeue {
    id headObject = [self objectAtIndex:0];
    if (headObject != nil) {
        [self removeObjectAtIndex:0];
    }
    return headObject;
}

- (void) enqueue:(id)anObject {
    [self addObject:anObject];
}

- (id)peek {
    id headObject = [self objectAtIndex:0];
    return headObject;
}

@end
