//
//  STRAdFixtures.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdVine, STRAdYouTube;

@interface STRAdFixtures : NSObject

+ (STRAdYouTube *)youTubeAd;
+ (STRAdVine *)vineAd;

@end
