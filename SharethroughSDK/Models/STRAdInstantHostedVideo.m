//
//  STRAdInstantHostedVideo.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 9/16/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import "STRAdInstantHostedVideo.h"

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

@interface STRAdInstantHostedVideo ()

@property (strong, nonatomic) AVQueuePlayer *avPlayer;
@property (nonatomic, readwrite) BOOL beforeEngagement;

@property (strong, nonatomic) id silentPlayTimer;
@property (strong, nonatomic) id quartileTimer;

@end

@implementation STRAdInstantHostedVideo

@synthesize mediaURL = _mediaURL;

- (id)initWithInjector:(STRInjector *)injector {
    if (self = [super initWithInjector:injector]) {
        self.avPlayer = [self.injector getInstance:[AVQueuePlayer class]];
        [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
        self.beforeEngagement = YES;
    }
    return self;
}

- (void)dealloc {
    [self.avPlayer removeTimeObserver:self.silentPlayTimer];
    [self.avPlayer removeTimeObserver:self.quartileTimer];
    [self.avPlayer removeObserver:self forKeyPath:@"rate"];
}

- (void)setMediaURL:(NSURL *)mediaURL {
    if (self.mediaURL != mediaURL) {
        _mediaURL = mediaURL;
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:mediaURL options:nil];
        [asset loadValuesAsynchronouslyForKeys:@[@"playable"] completionHandler:^() {
            [self.avPlayer insertItem:[AVPlayerItem playerItemWithAsset:asset] afterItem:nil];
            [self setupSilentPlayTimer];
            [self setupQuartileTimer];
        }];
    }
}

- (UIImage *)centerImage {
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
    }
}

- (UIViewController*) viewControllerForPresentingOnTap {
    if (self.beforeEngagement) {
        [self.avPlayer removeTimeObserver:self.silentPlayTimer];

        CMTime time = [self.avPlayer currentTime];
        STRBeaconService *beaconService = [self.injector getInstance:[STRBeaconService class]];
        [beaconService fireAutoPlayVideoEngagementForAd:self withDuration:CMTimeGetSeconds(time) * 1000];
    }

    self.beforeEngagement = NO;

    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    playerViewController.player = self.avPlayer;
    self.avPlayer.muted = false;
    return playerViewController;
}

- (BOOL)adVisibleInView:(UIView *)view {
    if (self.beforeEngagement) {
        if (self.avPlayer.rate == 0.0) {
            [self.avPlayer play];
        }
        return YES;
    }
    return NO;
}

- (BOOL)adNotVisibleInView:(UIView *)view {
    if (self.beforeEngagement) {
        [self.avPlayer pause];
        return YES;
    }
    return NO;
}

#pragma mark - Private

- (void)setupSilentPlayTimer {
    if (self.silentPlayTimer == nil) {
        __block AVQueuePlayer *blockPlayer = self.avPlayer;
        __block STRBeaconService *blockBeconService = [self.injector getInstance:[STRBeaconService class]];
        __block STRAdInstantHostedVideo *blockSelf = self;

        NSValue *threeSecond = [NSValue valueWithCMTime:CMTimeMake(3, 1)], *tenSecond = [NSValue valueWithCMTime:CMTimeMake(10, 1)],
                *fifteenSecond = [NSValue valueWithCMTime:CMTimeMake(15, 1)], *thirtySecond = [NSValue valueWithCMTime:CMTimeMake(30, 1)];

        self.silentPlayTimer = [self.avPlayer addBoundaryTimeObserverForTimes:@[threeSecond, tenSecond, fifteenSecond, thirtySecond] queue:nil usingBlock:^{
            CMTime time = [blockPlayer currentTime];
            Float64 seconds = CMTimeGetSeconds(time);
            [blockBeconService fireSilentAutoPlayDurationForAd:blockSelf withDuration:seconds * 1000];
            if (floorf(seconds) == 3) {
                [blockBeconService fireThirdPartyBeacons:blockSelf.thirdPartyBeaconsForSilentPlay forPlacementWithStatus:blockSelf.placementStatus];
            } else if (floorf(seconds) == 10) {
                [blockBeconService fireThirdPartyBeacons:blockSelf.thirdPartyBeaconsForTenSecondSilentPlay forPlacementWithStatus:blockSelf.placementStatus];
            } else if (floorf(seconds) == 15) {
                [blockBeconService fireThirdPartyBeacons:blockSelf.thirdPartyBeaconsForFifteenSecondSilentPlay forPlacementWithStatus:blockSelf.placementStatus];
            } else if (floorf(seconds) == 30) {
                [blockBeconService fireThirdPartyBeacons:blockSelf.thirdPartyBeaconsForThirtySecondSilentPlay forPlacementWithStatus:blockSelf.placementStatus];
            }
        }];
    }
}

- (void)setupQuartileTimer {
    if (self.quartileTimer == nil) {
        __block AVQueuePlayer *blockPlayer = self.avPlayer;
        __block STRBeaconService *blockBeconService = [self.injector getInstance:[STRBeaconService class]];
        __block STRAdInstantHostedVideo *blockSelf = self;

        Float64 seconds = CMTimeGetSeconds(self.avPlayer.currentItem.asset.duration);
        NSValue *TwentyFivePercent = [NSValue valueWithCMTime:CMTimeMake(seconds *.25, 1)],
                *FiftyPercent = [NSValue valueWithCMTime:CMTimeMake(seconds * .5, 1)],
                *SeventyFivePercent = [NSValue valueWithCMTime:CMTimeMake(seconds *.75, 1)],
                *NinteyFivePercent = [NSValue valueWithCMTime:CMTimeMake(seconds * .95, 1)];

        self.quartileTimer = [self.avPlayer addBoundaryTimeObserverForTimes:@[TwentyFivePercent, FiftyPercent, SeventyFivePercent, NinteyFivePercent] queue:nil usingBlock:^{
            NSNumber *completionPercent;
            Float64 percent = CMTimeGetSeconds([blockPlayer currentTime]) / seconds;
            if (percent <= 0.26) {
                completionPercent = [NSNumber numberWithInt:25];
            } else if (percent > 0.26 && percent <= 0.51 ) {
                completionPercent = [NSNumber numberWithInt:50];
            } else if (percent > 0.51 && percent <= 0.76) {
                completionPercent = [NSNumber numberWithInt:75];
            } else {
                completionPercent = [NSNumber numberWithInt:95];
                [blockBeconService fireThirdPartyBeacons:blockSelf.thirdPartyBeaconsForCompletedSecondSilentPlay forPlacementWithStatus:blockSelf.placementStatus];
            }

            [blockBeconService fireVideoCompletionForAd:blockSelf completionPercent:completionPercent];
        }];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.avPlayer.rate == 0.0) {
        STRBeaconService *beaconService = [self.injector getInstance:[STRBeaconService class]];
        [beaconService fireVideoViewDurationForAd:self withDuration:CMTimeGetSeconds([self.avPlayer currentTime]) isSilent:self.avPlayer.muted];
    }
}
@end
