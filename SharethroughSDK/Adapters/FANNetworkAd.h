//
//  FANNetworkAd.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 8/19/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#if __has_include(<SharethroughSDK/SharethroughSDK.h>)
    #import <SharethroughSDK/SharethroughSDK.h>
#else
    #import "STRAdvertisement.h"
#endif

@class FBNativeAd;

@interface FANNetworkAd : STRAdvertisement

- (id)initWithFBNativeAd:(FBNativeAd *)nativeAd;

@end
