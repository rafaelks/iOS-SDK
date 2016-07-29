//
//  STRMediationDelegate.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 7/26/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

@class STRAdvertisement, STRMediationAdapter;


@protocol STRMediationDelegate <NSObject>


- (void)mediationAdapter:(STRMediationAdapter *)adapter didFetchAd:(STRAdvertisement *)strAd;


- (void)mediationAdapter:(STRMediationAdapter *)adapter didFailToFetchAdWithError:(NSError *)error;

@end
