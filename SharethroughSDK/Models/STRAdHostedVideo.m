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

@interface InstantPlayWrapperView : UIImageView

@property (strong, nonatomic) AVPlayerLayer *avlayer;

@end

@implementation InstantPlayWrapperView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avlayer.frame = self.bounds;
}

@end

#pragma - mark STRAdHostedVideo

@interface STRAdHostedVideo ()

@property (strong, nonatomic) AVQueuePlayer *avPlayer;
@property (strong, nonatomic) id silentPlayTimer;
@property (nonatomic, readwrite) BOOL beforeEngagement;

@end

@implementation STRAdHostedVideo

@synthesize mediaURL = _mediaURL;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.avPlayer = [AVQueuePlayer new];
        self.beforeEngagement = YES;
    }
    return self;
}

- (void)dealloc {
    [self.avPlayer removeTimeObserver:self.silentPlayTimer];
    [self.simpleVisibleTimer invalidate];
}

- (void)setMediaURL:(NSURL *)mediaURL {
    if (self.mediaURL != mediaURL) {
        _mediaURL = mediaURL;
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:nil];
        [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^() {
            [self.avPlayer insertItem:[AVPlayerItem playerItemWithAsset:asset] afterItem:nil];
        }];
    }
}

- (UIImage *)centerImage {
    if (false) //TODO: this should be determined based on whether can autoplay
        return [STRImages playBtn];
    else
        return nil;
}

- (void)setThumbnailImageInView:(UIImageView *)imageView {
    imageView.image = self.thumbnailImage;
    if (self.beforeEngagement) {
        InstantPlayWrapperView *wrapperView = [[InstantPlayWrapperView alloc] initWithFrame:imageView.bounds];
        [wrapperView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [imageView addSubview:wrapperView];

        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        layer.videoGravity = AVLayerVideoGravityResize;
        layer.frame = wrapperView.bounds;
        [wrapperView.layer addSublayer: layer];
        wrapperView.image = self.thumbnailImage;
        [wrapperView setNeedsLayout];

        self.avPlayer.muted = YES;
        [self.avPlayer play];

        [self setupSilentPlayTimer];
    }
}

- (void)setupSilentPlayTimer {
    if (self.silentPlayTimer == nil) {
        __block AVQueuePlayer *blockPlayer = self.avPlayer;
        __block STRBeaconService *blockBeconService = [self.injector getInstance:[STRBeaconService class]];
        __block STRAdHostedVideo *blockSelf = self;

        NSValue *threeSecond = [NSValue valueWithCMTime:CMTimeMake(3, 1)], *tenSecond = [NSValue valueWithCMTime:CMTimeMake(10, 1)];

        self.silentPlayTimer = [self.avPlayer addBoundaryTimeObserverForTimes:@[threeSecond, tenSecond] queue:nil usingBlock:^{
            CMTime time = [blockPlayer currentTime];
            [blockBeconService fireSilentAutoPlayDurationForAd:blockSelf withDuration:(time.value/time.timescale)];
        }];
    }
}

- (UIViewController*) viewControllerForPresentingOnTapWithInjector:(STRInjector *)injector {
    if (self.beforeEngagement) {
        [self.avPlayer removeTimeObserver:self.silentPlayTimer];

        CMTime time = [self.avPlayer currentTime];
        STRBeaconService *beaconService = [self.injector getInstance:[STRBeaconService class]];
        [beaconService fireAutoPlayVideoEngagementForAd:self withDuration:(time.value/time.timescale)];
    }

    self.beforeEngagement = NO;

    [self.simpleVisibleTimer invalidate];

    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = self.avPlayer;
    self.avPlayer.muted = false;
    return playerViewController;
}

- (void)adVisibleInView:(UIView *)view {
    if (self.beforeEngagement) {
        [self.avPlayer play];
    }
}

- (void)adNotVisibleInView:(UIView *)view {
    if (self.beforeEngagement) {
        [self.avPlayer pause];
    }
}
@end
