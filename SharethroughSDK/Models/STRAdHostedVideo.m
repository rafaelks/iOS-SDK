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


@interface InstantPlayWrapperView : UIView

@property (strong, nonatomic) AVPlayerLayer *avlayer;

@end

@implementation InstantPlayWrapperView

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avlayer.frame = self.bounds;
    NSLog(@"Layout subviews: layerFrame: %@, layerBounds: %@, selfBounds: %@, selfFrame:%@",
          NSStringFromCGRect(self.avlayer.frame),
          NSStringFromCGRect(self.avlayer.bounds),
          NSStringFromCGRect(self.bounds),
          NSStringFromCGRect(self.frame));
}

@end

#pragma - mark STRAdHostedVideo

@interface STRAdHostedVideo ()

@property (strong, nonatomic) AVQueuePlayer *avPlayer;

@end

@implementation STRAdHostedVideo

- (instancetype)init {
    NSLog(@"init");
    self = [super init];
    if (self) {
        NSLog(@"got self");
        self.avPlayer = [AVQueuePlayer new];
//        self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.mediaURL options:nil];
        [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^() {
            NSLog(@"loaded asset");
            [self.avPlayer insertItem:[AVPlayerItem playerItemWithAsset:asset] afterItem:nil];
        }];
    }
    return self;
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

    //For testing only!
    imageView.image = self.thumbnailImage;
    imageView.backgroundColor = [UIColor redColor];
    wrapperView.backgroundColor = [UIColor purpleColor];

    self.avPlayer.muted = NO;
    [self.avPlayer play];
}

- (UIViewController*) viewControllerForPresentingOnTapWithInjector:(STRInjector *)injector {
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = self.avPlayer;
    self.avPlayer.muted = false;
    return playerViewController;
}

@end
