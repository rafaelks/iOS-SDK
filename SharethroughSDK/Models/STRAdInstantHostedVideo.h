//
//  STRAdInstantHostedVideo.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 9/16/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"

@interface STRAdInstantHostedVideo : STRAdvertisement

@property (nonatomic, readonly) BOOL beforeEngagement;

#pragma mark - Private, exposed only for testing
- (void)setupSilentPlayTimer;
- (void)setupQuartileTimer;

@end
