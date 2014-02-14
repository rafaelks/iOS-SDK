//
//  STRTestSafeModule.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/14/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTestSafeModule.h"
#import "STRFakeAdGenerator.h"
#import "STRBeaconService.h"
#import "STRAdService.h"

@interface STRTestSafeModule ()

@property (assign, nonatomic) STRFakeAdType adType;

@end

@implementation STRTestSafeModule

- (id)initWithAdType:(STRFakeAdType)adType {
    self = [super init];
    if (self) {
        self.adType = adType;
    }

    return self;
}

- (void)configureWithInjector:(STRInjector *)injector {
    [super configureWithInjector:injector];

    STRFakeAdType type = self.adType;
    [injector bind:[STRAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRFakeAdGenerator alloc] initWithAdType:type withInjector:injector];
    }];
    [injector bind:[STRBeaconService class] toInstance:[NSNull null]];
    [injector bind:[STRAdService class] toInstance:[NSNull null]];
}

@end
