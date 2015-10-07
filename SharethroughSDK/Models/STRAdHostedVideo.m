//
//  STRAdHostedVideo.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 9/9/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import "STRAdHostedVideo.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

#import "STRImages.h"
#import "STRBeaconService.h"
#import "STRInjector.h"

@implementation STRAdHostedVideo

- (UIImage *)centerImage {
    return [STRImages playBtn];
}

@end
