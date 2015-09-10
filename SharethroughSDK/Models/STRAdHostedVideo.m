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

@property (strong, nonatomic) AVPlayer *avPlayer;

@end

@implementation STRAdHostedVideo

- (UIImage *)centerImage {
    return [STRImages playBtn];
}

- (void)setThumbnailImageInView:(UIImageView *)imageView {
    self.avPlayer = [AVPlayer playerWithURL:self.mediaURL];
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;

    InstantPlayWrapperView *wrapperView = [[InstantPlayWrapperView alloc] initWithFrame:imageView.bounds];
    [wrapperView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [imageView addSubview:wrapperView];

    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    layer.videoGravity = AVLayerVideoGravityResize;
    layer.frame = wrapperView.bounds;
    [wrapperView.layer addSublayer: layer];
    imageView.backgroundColor = [UIColor redColor];
    wrapperView.backgroundColor = [UIColor purpleColor];

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
