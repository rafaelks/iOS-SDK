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
#import "STRNetworkAdapter.h"
#import "STRNetworkAdapterDelegate.h"
#import "STRPromise.h"

@interface PlacementMediationState : NSObject

@property (nonatomic, strong) NSArray *mediationNetworks;
@property (nonatomic) int mediationIndex;

- (id)initWithParameters:(NSArray *)mediationNetworks;

@end

@implementation PlacementMediationState

- (id)initWithParameters:(NSArray *)mediationNetworks {
    self = [super init];
    if (self) {
        self.mediationNetworks = mediationNetworks;
        self.mediationIndex = 0;
    }
    return self;
}

@end

@interface STRMediationService() <STRNetworkAdapterDelegate>

@property (nonatomic, strong) NSMutableDictionary *placementMediationNetworks;
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
    PlacementMediationState *placementMediationState =  [self getMediationStateForPlacement:placement withParameters:asapResponse];

    NSDictionary *currentNetwork = placementMediationState.mediationNetworks[placementMediationState.mediationIndex];
    NSString *mediationClassName = currentNetwork[@"iosClassName"];
    STRNetworkAdapter *networkAdapter = (STRNetworkAdapter *)[[NSClassFromString(mediationClassName) alloc] init];
    networkAdapter.delegate = self;

    if (![networkAdapter isKindOfClass:[STRNetworkAdapter class]]) {
        NSLog(@"**** MediationClassName: %@ does not extend STRNetworkAdapter ****", mediationClassName);
        return nil;
    }

    [networkAdapter loadAdWithParameters:currentNetwork[@"parameters"]];

    return [[STRPromise alloc] init];
}

- (PlacementMediationState *)getMediationStateForPlacement:(STRAdPlacement *)placement withParameters:(NSDictionary *)asapResponse {
    if ([self.placementMediationNetworks objectForKey:placement.placementKey]) {
        return [self.placementMediationNetworks objectForKey:placement.placementKey];
    } else {
        PlacementMediationState *newState = [[PlacementMediationState alloc] initWithParameters:asapResponse[@"mediationNetworks"]];
        self.placementMediationNetworks[placement.placementKey] = newState;
        return newState;
    }
}

-(void)strNetworkAdapter:(STRNetworkAdapter *)adapter didLoadAd:(STRAdvertisement *)strAd {
    NSLog(@"Did ad load? Ad did load!");
    //ad loaded, fulfill promise
}

-(void)strNetworkAdapter:(STRNetworkAdapter *)adapter didFailToLoadAdWithError:(NSError *)error {
    //ad failed to load, try next network
    NSLog(@"didFailToLoadAdWithError %@", error);
}

@end
