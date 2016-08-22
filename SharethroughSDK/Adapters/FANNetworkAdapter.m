//
//  FANNetworkAdapter.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 8/19/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "FANNetworkAdapter.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "FANNetworkAd.h"

@interface FANNetworkAdapter() <FBNativeAdDelegate>

@property (nonatomic, strong) FBNativeAd *fbNativeAd;

@end

@implementation FANNetworkAdapter

-(void)dealloc {
    NSLog(@"Going away");
}

-(void)loadAdWithParameters:(NSDictionary *)parameters {
    NSString *placementId = [parameters objectForKey:@"fanPlacementId"];

    if (placementId) {
        self.fbNativeAd = [[FBNativeAd alloc] initWithPlacementID:placementId];
        self.fbNativeAd.delegate = self;
        self.fbNativeAd.mediaCachePolicy = FBNativeAdsCachePolicyAll;
        [self.fbNativeAd loadAd];
    } else {
        [self.delegate strNetworkAdapter:self didFailToLoadAdWithError:[NSError errorWithDomain:@"Missing FAN Placement ID" code:404 userInfo:nil]];
    }
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
    NSLog(@"Got FAN ad");
    STRAdvertisement *strAd = [[FANNetworkAd alloc] initWithFBNativeAd:nativeAd];
    [self.delegate strNetworkAdapter:self didLoadAd:strAd];
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
    NSLog(@"failed to get fan ad");
    [self.delegate strNetworkAdapter:self didFailToLoadAdWithError:error];
}

@end
