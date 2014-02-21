//
//  STRAdFixtures.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdFixtures.h"
#import "STRAdYouTube.h"
#import "STRAdVine.h"
#import "STRAdvertisement.h"
#import "images.h"
#import "STRAdClickout.h"

@implementation STRAdFixtures

+ (STRAdvertisement *)ad {
    STRAdvertisement *ad = [STRAdvertisement new];
    ad.mediaURL = [NSURL URLWithString:@"http://brightcove.vo.llnwd.net/9u9e1zone-minute-video.mp4"];
    ad.title = @"Superad";
    ad.shareURL = [NSURL URLWithString:@"http://sharethrough.ly/23asdf"];

    return ad;
}

+ (STRAdYouTube *)youTubeAd {
    STRAdYouTube *ad = [STRAdYouTube new];
    ad.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=YSVL4FvFhvw"];
    ad.title = @"Go Sip for Sip with Josh Duhamel";
    ad.shareURL = [NSURL URLWithString:@"http://bit.ly/23kljr"];
    ad.adDescription = @"Grab a Diet Pepsi and share a delicious moment with Josh Duhamel";
    ad.advertiser = @"Pepsi";
    ad.action = STRYouTubeAd;
    ad.thumbnailImage = [UIImage imageWithData:[NSData dataWithBytes:kSTRYoutubeThumbnail.bytes length:kSTRYoutubeThumbnail.length]];

    return ad;
}

+ (STRAdVine *)vineAd {
    STRAdVine *ad = [STRAdVine new];
    ad.mediaURL = [NSURL URLWithString:@"https://v.cdn.vine.co/r/videos/6CB419768A995421752886763520_10c1db02719.3.2_WvWVlM.kjm_rWfdKEnd.GNuCbvrPUbFRzc1tYb_krsyuepSZq4_L.bu_8BmJNZLj.mp4"];
    ad.title = @"Meet A 15-year-old Cancer Researcher";
    ad.shareURL = [NSURL URLWithString:@"http://vine.ly/share"];
    ad.adDescription = @"Meet Jack Andraka. Inventor, cancer researcher, 15 year old #ISEF winner. #findacure #lookinside";
    ad.action = STRVineAd;
    ad.thumbnailImage = [UIImage imageWithData:[NSData dataWithBytes:kSTRVineThumbnail.bytes length:kSTRVineThumbnail.length]];
    ad.advertiser = @"Intel";

    return ad;
}

+ (STRAdvertisement *)hostedVideoAd {
    STRAdvertisement *ad = [STRAdvertisement new];
    ad.mediaURL = [NSURL URLWithString:@"http://media.sharethrough.com.s3.amazonaws.com/Val/iOS%20SDK%20Stuff/Media/New%20Silk%20ad%20-%20Whaddya%20think_%20Share%20your%20thoughts!.mp4"];
    ad.title = @"Avoid the morning MOO";
    ad.shareURL = [NSURL URLWithString:@"http://bit.ly/share"];
    ad.adDescription = @"Avoid the taste of the dreaded MOO and make your morning taste better with Silk Almond Milk";
    ad.action = STRHostedVideoAd;
    ad.thumbnailImage = [UIImage imageWithData:[NSData dataWithBytes:kSTRHostedVideoThumbnail.bytes length:kSTRHostedVideoThumbnail.length]];
    ad.advertiser = @"Silk";

    return ad;
}

+ (STRAdClickout *)clickoutAd {
    STRAdClickout *ad = [STRAdClickout new];
    ad.mediaURL = [NSURL URLWithString:@"http://www.buzzfeed.com/mcdonaldsmightywings/game-day-gifs-that-will-pump-you-up-for-anything?b=1"];
    ad.title = @"22 Game Day Gifs That Will Pump You Up For Anything";
    ad.shareURL = [NSURL URLWithString:@"http://bit.ly/share"];
    ad.adDescription = @"Get in the zone and check out these GIFs before your next big challenge to ensure victory. Then taste the winning kick of McDonald's® Mighty Wings® , now available nationwide.";
    ad.action = STRClickoutAd;
    ad.thumbnailImage = [UIImage imageWithData:[NSData dataWithBytes:kSTRClickoutThumbnail.bytes length:kSTRClickoutThumbnail.length]];
    ad.advertiser = @"McDonald's";

    return ad;
}

@end
