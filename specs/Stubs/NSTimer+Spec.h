//
//  NSTimer+Spec.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (Spec)

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti target:(id)aTarget selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;

+ (id)target;
+ (SEL)action;
+ (BOOL)isRepeating;
+ (NSDictionary *)userInfo;
+ (void)clear;

@end
