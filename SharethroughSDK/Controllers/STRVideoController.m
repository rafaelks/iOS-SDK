//
//  STRVideoController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRVideoController.h"

#import <MediaPlayer/MediaPlayer.h>

#import "STRAdvertisement.h"
#import "STRAdVine.h"
#import "STRBeaconService.h"


@interface STRVideoController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (strong, nonatomic, readwrite) MPMoviePlayerController *moviePlayerController;
@property (weak, nonatomic) STRBeaconService *beaconService;
@property (weak, nonatomic, readwrite) UIView *moviePlayerView;
@property (weak, nonatomic, readwrite) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableArray *firedCompletionBeacons;

@end

@implementation STRVideoController

- (id)initWithAd:(STRAdvertisement *)ad moviePlayerController:(MPMoviePlayerController *)moviePlayerController beaconService:(STRBeaconService *)beaconService {
    self = [super init];
    if (self) {
        self.ad = ad;
        self.beaconService = beaconService;
        self.moviePlayerController = moviePlayerController;
        self.moviePlayerController.contentURL = ad.mediaURL;
        [self.moviePlayerController prepareToPlay];
        if ([self.ad isKindOfClass:[STRAdVine class]]) {
            self.moviePlayerController.repeatMode = MPMovieRepeatModeOne;
        }
        self.firedCompletionBeacons = [NSMutableArray arrayWithArray:@[@NO, @NO, @NO, @NO]];
    }
    
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self attachMoviePlayerView];
    [self addSpinner];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerIsReady:) name:MPMoviePlayerReadyForDisplayDidChangeNotification object:self.moviePlayerController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerPlaybackTimers:) name:MPMovieDurationAvailableNotification object:self.moviePlayerController];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerReadyForDisplayDidChangeNotification object:self.moviePlayerController];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMovieDurationAvailableNotification object:self.moviePlayerController];

    [self.timer invalidate];
}


#pragma mark - Private

- (void)playerIsReady:(NSNotification *)notification {
    [self.spinner removeFromSuperview];
}

- (void)registerPlaybackTimers:(NSNotification *)notification {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireCompletionBeacon) userInfo:nil repeats:YES];
}

- (void)fireCompletionBeacon {
    float completionPercent = (self.moviePlayerController.currentPlaybackTime / self.moviePlayerController.duration) * 100;

    if (completionPercent >= 95 && [self.firedCompletionBeacons[3] boolValue] == NO) {
        [self.timer invalidate];
        self.firedCompletionBeacons[3] = [NSNumber numberWithBool:YES];
        [self.beaconService fireVideoCompletionForAd:self.ad completionPercent:[NSNumber numberWithInt:95]];
    } else if (completionPercent >= 75 && completionPercent < 95 && [self.firedCompletionBeacons[2] boolValue] == NO) {
        self.firedCompletionBeacons[2] = [NSNumber numberWithBool:YES];
        [self.beaconService fireVideoCompletionForAd:self.ad completionPercent:[NSNumber numberWithInt:75]];
    } else if (completionPercent >= 50 && completionPercent < 75 && [self.firedCompletionBeacons[1] boolValue] == NO) {
        self.firedCompletionBeacons[1] = [NSNumber numberWithBool:YES];
        [self.beaconService fireVideoCompletionForAd:self.ad completionPercent:[NSNumber numberWithInt:50]];
    } else if (completionPercent >= 25 && completionPercent < 50 && [self.firedCompletionBeacons[0] boolValue] == NO) {
        self.firedCompletionBeacons[0] = [NSNumber numberWithBool:YES];
        [self.beaconService fireVideoCompletionForAd:self.ad completionPercent:[NSNumber numberWithInt:25]];
    }
}

- (void)addSpinner {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spinner startAnimating];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:spinner];
    self.spinner = spinner;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.spinner
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.spinner
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
}

- (void)attachMoviePlayerView {
    UIView *moviePlayerView = self.moviePlayerController.view;
    self.moviePlayerView = moviePlayerView;
    moviePlayerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:moviePlayerView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[moviePlayerView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(moviePlayerView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[moviePlayerView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(moviePlayerView)]];
}
@end
