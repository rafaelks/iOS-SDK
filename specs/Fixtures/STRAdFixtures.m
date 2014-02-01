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

@implementation STRAdFixtures

+ (STRAdYouTube *)youTubeAd {
    STRAdYouTube *ad = [STRAdYouTube new];
    ad.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=BWAK0J8Uhzk"];
    ad.title = @"Superad";
    ad.shareURL = [NSURL URLWithString:@"http://bit.ly/23kljr"];

    return ad;
}

+ (STRAdVine *)vineAd {
    STRAdVine *ad = [STRAdVine new];
    ad.mediaURL = [NSURL URLWithString:@"http://www.vine.com/some.mp4"];
    ad.title = @"Superad";
    ad.shareURL = [NSURL URLWithString:@"http://vine.ly/share"];

    return ad;
}

@end
