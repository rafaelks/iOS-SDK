//
//  FANMediationAdapter.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 7/26/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "FANMediationAdapter.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import "FANMediationAd.h"
#import "STRAdvertisement.h"

@interface FANMediationAdapter() <FBNativeAdDelegate>

@property (nonatomic, strong) FBNativeAd *fbNativeAd;

@end

@implementation FANMediationAdapter

- (void)fetchAdWithCustomParameters:(NSDictionary *)parameters {

    NSString *placementId = [parameters objectForKey:@"placement_id"];

    if (placementId) {
        self.fbNativeAd = [[FBNAtiveAd alloc] initWithPlacementID:placementId];
        self.fbNativeAd.delegate = self;
        [self.fbNativeAd loadAd];
    } else {
        [self.delegate mediationAdapter:self didFailToFetchAdWithError:[NSError errorWithDomain:@"Missing FAN Placement ID" code:404 userInfo:nil]];
    }
}

#pragma mark - FBNativeAdDelegate

- (void)nativeAdDidLoad:(FBNativeAd *)nativeAd {
    STRAdvertisement *strAd = [[FANMediationAd alloc] initWithFBNativeAd:nativeAd];
    [self.delegate mediationAdapter:self didFetchAd:strAd];
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error {
    [self.delegate mediationAdapter:self didFailToFetchAdWithError:error];
}

@end
