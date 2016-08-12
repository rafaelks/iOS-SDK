//
//  STRNetworkAdapterDelegate.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

@class STRAdvertisement;

@protocol STRNetworkAdapterDelegate <NSObject>

- (void)adDidLoad:(STRAdvertisement *)strAd;

- (void)adDidFailToLoad:(NSError *)error;

@end