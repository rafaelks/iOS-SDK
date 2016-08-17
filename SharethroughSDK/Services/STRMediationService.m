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

    [self loadAdForPlacementMediationState:placementMediationState withPlacement:placement];
}

#pragma mark - STRNetworkAdapterDelegate

-(void)strNetworkAdapter:(STRNetworkAdapter *)adapter didLoadAd:(STRAdvertisement *)strAd {
    NSLog(@"Did ad load? Ad did load!");
    [self storeCreativesForAdapter:adapter andStoreCreatives:@[strAd]];
}

- (void)strNetworkAdapter:(STRNetworkAdapter *)adapter didLoadMultipleAds:(NSArray *)strAds {
    NSLog(@"Did ad load? Many ads did load!");
    [self storeCreativesForAdapter:adapter andStoreCreatives:strAds];
}

-(void)strNetworkAdapter:(STRNetworkAdapter *)adapter didFailToLoadAdWithError:(NSError *)error {
    //TODO: ad failed to load, try next network
    NSLog(@"didFailToLoadAdWithError %@", error);
    PlacementMediationState *mediationState = [self.placementMediationNetworks objectForKey:adapter.placement.placementKey];
    [self.adCache clearPendingAdRequestForPlacement:adapter.placement.placementKey];
    [self mediateNextNetworkForMediationState:mediationState withPlacement:adapter.placement];
}

#pragma mark - Private
- (PlacementMediationState *)getMediationStateForPlacement:(STRAdPlacement *)placement withParameters:(NSDictionary *)asapResponse {
    if ([self.placementMediationNetworks objectForKey:placement.placementKey]) {
        return [self.placementMediationNetworks objectForKey:placement.placementKey];
    } else {
        PlacementMediationState *newState = [[PlacementMediationState alloc] initWithParameters:asapResponse[@"mediationNetworks"]];
        self.placementMediationNetworks[placement.placementKey] = newState;
        return newState;
    }
}

- (void)storeCreativesForAdapter:(STRNetworkAdapter *)adapter andStoreCreatives:(NSArray *)strAds {
    PlacementMediationState *mediationState = [self.placementMediationNetworks objectForKey:adapter.placement.placementKey];
    [self.adCache clearPendingAdRequestForPlacement:adapter.placement.placementKey];
    [self.adCache saveAds:[[NSMutableArray alloc] initWithArray:strAds] forPlacement:adapter.placement andAssignAds:NO];
    [mediationState.deferred resolveWithValue:strAds[0]];
}

- (void)mediateNextNetworkForMediationState:(PlacementMediationState *)mediationState withPlacement:(STRAdPlacement *)placement{
    mediationState.mediationIndex++;
    if (mediationState.mediationIndex >= [mediationState.mediationNetworks count]) {
        [mediationState.deferred rejectWithError:[NSError errorWithDomain:@"No networks returned any ads" code:404 userInfo:nil]];
    } else {
        [self loadAdForPlacementMediationState:mediationState withPlacement:placement];
    }
}

- (void)loadAdForPlacementMediationState:(PlacementMediationState *)mediationState withPlacement:(STRAdPlacement *)placement {
    NSDictionary *currentNetwork = mediationState.mediationNetworks[mediationState.mediationIndex];
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

@end
