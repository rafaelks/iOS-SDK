//
//  STRMediationService.m
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "STRMediationService.h"

#import "STRDeferred.h"
#import "STRLogging.h"
#import "STRPromise.h"


@interface STRMediationService()

@property (nonatomic, strong) NSArray *mediationNetworks;
@property (nonatomic) int currentNetworkIndex;

@end


@implementation STRMediationService

- (id)init:(NSArray *)mediationNetworks {
    // store mediation network order
    // store current state
    self = [super init];
    if (self) {
        self.mediationNetworks = mediationNetworks;
        self.currentNetworkIndex = 0;
    }
    return self;
}

- (STRPromise *)fetchAd {
    NSDictionary *currentNetwork = self.mediationNetworks[self.currentNetworkIndex];
    NSString *mediationClassName = currentNetwork[@"iosClassName"];
    id networkAdapter = [[NSClassFromString(mediationClassName) alloc] init];
    //validate networkAdapter conforms to interface
//    [networkAdapter loadAdWithParameters:currentNetwork[@"parameters"]];
    return [[STRPromise alloc] init];
}

@end
