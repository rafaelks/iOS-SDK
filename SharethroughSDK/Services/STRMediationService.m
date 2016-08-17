//
//  STRMediationService.m
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "STRMediationService.h"

#import "STRAdCache.h"
#import "STRAdPlacement.h"
#import "STRDeferred.h"
#import "STRInjector.h"
#import "STRLogging.h"
#import "STRNetworkAdapter.h"
#import "STRNetworkAdapterDelegate.h"
#import "STRPromise.h"

@interface PlacementMediationState : NSObject

@property (nonatomic, strong) NSArray *mediationNetworks;
@property (nonatomic, strong) STRDeferred *deferred;
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
@property (nonatomic, strong) STRAdCache *adCache;

@end


@implementation STRMediationService

- (id)initWithInjector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.injector = injector;
        self.placementMediationNetworks = [[NSMutableDictionary alloc] init];
        self.adCache = [self.injector getInstance:[STRAdCache class]];
    }
    return self;
}

- (void)fetchAdForPlacement:(STRAdPlacement *)placement withParameters:(NSDictionary *)asapResponse forDeferred:(STRDeferred *)deferred {
    PlacementMediationState *placementMediationState =  [self getMediationStateForPlacement:placement withParameters:asapResponse];
    placementMediationState.deferred = deferred;

    NSDictionary *currentNetwork = placementMediationState.mediationNetworks[placementMediationState.mediationIndex];
    NSString *mediationClassName = currentNetwork[@"iosClassName"];
    STRNetworkAdapter *networkAdapter = (STRNetworkAdapter *)[[NSClassFromString(mediationClassName) alloc] init];

    if (![networkAdapter isKindOfClass:[STRNetworkAdapter class]]) {
        NSLog(@"**** MediationClassName: %@ does not extend STRNetworkAdapter ****", mediationClassName);
        return;
    }
    networkAdapter.delegate = self;
    networkAdapter.placement = placement;
    networkAdapter.injector = self.injector;

    [networkAdapter loadAdWithParameters:currentNetwork[@"parameters"]];
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
    PlacementMediationState *mediationState = [self.placementMediationNetworks objectForKey:adapter.placement.placementKey];
    [self.adCache clearPendingAdRequestForPlacement:adapter.placement.placementKey];
    [mediationState.deferred resolveWithValue:strAd];
}

-(void)strNetworkAdapter:(STRNetworkAdapter *)adapter didFailToLoadAdWithError:(NSError *)error {
    //TODO: ad failed to load, try next network
    NSLog(@"didFailToLoadAdWithError %@", error);
    PlacementMediationState *mediationState = [self.placementMediationNetworks objectForKey:adapter.placement.placementKey];
    [self.adCache clearPendingAdRequestForPlacement:adapter.placement.placementKey];
    [mediationState.deferred rejectWithError:error];
}

@end
