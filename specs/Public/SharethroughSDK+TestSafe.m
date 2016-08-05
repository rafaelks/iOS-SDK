//
//  SharethroughSDK+Fake.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 8/5/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "SharethroughSDK+TestSafe.h"
#import "STRTestSafeModule.h"

@interface SharethroughSDK ()

@property (nonatomic, strong) STRInjector *injector;

@end

@implementation SharethroughSDK (TestSafeInstance)

+ (instancetype)sharedTestSafeInstanceWithAdType:(STRFakeAdType)adType {
    __strong static SharethroughSDK *testSafeSharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        testSafeSharedObject = [[self alloc] init];
    });

    testSafeSharedObject.injector = [STRInjector injectorForModule:[[STRTestSafeModule alloc] initWithAdType:adType]];

    return testSafeSharedObject;
}

@end
