//
//  STRVideoController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRVideoController.h"
#import "STRAdvertisement.h"
#import <MediaPlayer/MediaPlayer.h>

@interface STRVideoController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (strong, nonatomic, readwrite) MPMoviePlayerController *moviePlayerController;

@end

@implementation STRVideoController

- (id)initWithAd:(STRAdvertisement *)ad moviePlayerController:(MPMoviePlayerController *)moviePlayerController {
    self = [super init];
    if (self) {
        self.ad = ad;
        self.moviePlayerController = moviePlayerController;
        self.moviePlayerController.contentURL = ad.mediaURL;
        self.moviePlayerController.repeatMode = MPMovieRepeatModeOne;
        [self.moviePlayerController prepareToPlay];
    }
    
    return self;
}

- (void)loadView {
    self.view = self.moviePlayerController.view;
}

@end
