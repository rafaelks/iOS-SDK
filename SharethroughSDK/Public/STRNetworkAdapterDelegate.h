//
//  STRNetworkAdapterDelegate.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

@class STRAdvertisement, STRNetworkAdapter;

@protocol STRNetworkAdapterDelegate <NSObject>

- (void)strNetworkAdapter:(STRNetworkAdapter *)adapter didLoadAd:(STRAdvertisement *)strAd;

- (void)strNetworkAdapter:(STRNetworkAdapter *)adapter didLoadMultipleAds:(NSArray *)strAds;

- (void)strNetworkAdapter:(STRNetworkAdapter *)adapter didFailToLoadAdWithError:(NSError *)error;

@end