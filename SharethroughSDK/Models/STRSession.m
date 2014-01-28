//
//  STRSession.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRSession.h"

@implementation STRSession

+ (NSString *)sessionToken {
    static NSUUID *sessionUUID;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sessionUUID = [NSUUID UUID];
    });

    return [sessionUUID UUIDString];
}

@end
