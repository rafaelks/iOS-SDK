//
//  STRAdHostedVideo.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 9/9/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"

@interface STRAdHostedVideo : STRAdvertisement

@property (nonatomic, weak) NSTimer *simpleVisibleTimer;
@property (nonatomic, readonly) BOOL beforeEngagement;

@end
