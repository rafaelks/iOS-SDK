//
//  STRAdFixtures.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdVine, STRAdYouTube, STRAdvertisement, STRAdClickout, STRAdPinterest, STRAdInstagram, STRAdArticle, STRAdHostedVideo, STRAdInstantHostedVideo, STRInjector;

@interface STRAdFixtures : NSObject

+ (STRAdvertisement *)ad;
+ (STRAdYouTube *)youTubeAd;
+ (STRAdVine *)vineAd;
+ (STRAdHostedVideo *)hostedVideoAd;
+ (STRAdInstantHostedVideo *)instantPlayVideoAdWithInjector:(STRInjector *)inject;
+ (STRAdClickout *)clickoutAd;
+ (STRAdPinterest *)pinterestAd;
+ (STRAdClickout *)privacyInformationAdWithOptOutURL:(NSURL *)optOutURL;
+ (STRAdInstagram *)instagramAd;
+ (STRAdArticle *)articleAd;

@end
