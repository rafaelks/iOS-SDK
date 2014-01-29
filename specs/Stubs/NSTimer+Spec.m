//
//  NSTimer+Spec.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "NSTimer+Spec.h"

@implementation NSTimer (Spec)

static id target;
+ (id)target {
    return target;
}

static SEL action;
+ (SEL)action {
    return action;
}

static NSDictionary *userInfo;
+ (NSDictionary *)userInfo {
    return userInfo;
}

static BOOL isRepeating;
+ (BOOL)isRepeating {
    return isRepeating;
}

+ (void)clear {
    target = nil;
    action = NULL;
    userInfo = nil;
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)timerUserInfo repeats:(BOOL)repeats {
    target = aTarget;
    action = aSelector;
    userInfo = timerUserInfo;
    isRepeating = repeats;

    return nil;
}

@end
