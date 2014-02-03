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
#import "STRAdVine.h"

@interface STRVideoController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (strong, nonatomic, readwrite) MPMoviePlayerController *moviePlayerController;
@property (weak, nonatomic, readwrite) UIView *moviePlayerView;
@property (weak, nonatomic, readwrite) UIActivityIndicatorView *spinner;

@end

@implementation STRVideoController

- (id)initWithAd:(STRAdvertisement *)ad moviePlayerController:(MPMoviePlayerController *)moviePlayerController {
    self = [super init];
    if (self) {
        self.ad = ad;
        self.moviePlayerController = moviePlayerController;
        self.moviePlayerController.contentURL = ad.mediaURL;
        [self.moviePlayerController prepareToPlay];
        if ([self.ad isKindOfClass:[STRAdVine class]]) {
            self.moviePlayerController.repeatMode = MPMovieRepeatModeOne;
        }
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerReadyForDisplayDidChangeNotification object:self.moviePlayerController];
}


#pragma mark - Private

- (void)playerIsReady:(NSNotification *)notification {
    [self.spinner removeFromSuperview];
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
