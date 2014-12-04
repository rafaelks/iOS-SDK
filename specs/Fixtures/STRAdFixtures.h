//
//  STRAdFixtures.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdVine, STRAdYouTube, STRAdvertisement, STRAdClickout, STRAdPinterest, STRAdInstagram;

@interface STRAdFixtures : NSObject

+ (STRAdvertisement *)ad;
+ (STRAdYouTube *)youTubeAd;
+ (STRAdVine *)vineAd;
+ (STRAdvertisement *)hostedVideoAd;
+ (STRAdClickout *)clickoutAd;
+ (STRAdPinterest *)pinterestAd;
+ (STRAdInstagram *)instagramAd;

@end
