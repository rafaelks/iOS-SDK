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

@end

@implementation STRAdHostedVideo

- (instancetype)init {
    self = [super init];
    if (self) {
        self.avPlayer = [AVQueuePlayer new];
    }
    return self;
}

- (void)setMediaURL:(NSURL *)mediaURL {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:nil];
    [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^() {
        [self.avPlayer insertItem:[AVPlayerItem playerItemWithAsset:asset] afterItem:nil];
    }];
}

- (UIImage *)centerImage {
    return [STRImages playBtn];
}

- (void)setThumbnailImageInView:(UIImageView *)imageView {
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
}

- (UIViewController*) viewControllerForPresentingOnTapWithInjector:(STRInjector *)injector {
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = self.avPlayer;
    self.avPlayer.muted = false;
    return playerViewController;
}

@end
