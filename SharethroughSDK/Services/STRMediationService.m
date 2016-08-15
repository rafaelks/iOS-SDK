//
//  STRMediationService.m
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "STRMediationService.h"

#import "STRAdPlacement.h"
#import "STRDeferred.h"
#import "STRInjector.h"
#import "STRLogging.h"
#import "STRPromise.h"

@interface STRMediationService()

@property (nonatomic, strong) NSArray *mediationNetworks;
@property (nonatomic) int currentNetworkIndex;
@property (nonatomic, weak) STRInjector *injector;

@end


@implementation STRMediationService

- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
    }
    return self;
}

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement withParameters:(NSDictionary *)asapResponse {
    NSDictionary *currentNetwork = self.mediationNetworks[self.currentNetworkIndex];
    NSString *mediationClassName = currentNetwork[@"iosClassName"];
    id networkAdapter = [[NSClassFromString(mediationClassName) alloc] init];
    //validate networkAdapter conforms to interface
//    [networkAdapter loadAdWithParameters:currentNetwork[@"parameters"]];
    return [[STRPromise alloc] init];
}

@end
