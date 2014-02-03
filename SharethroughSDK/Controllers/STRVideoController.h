//
//  STRVideoController.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STRAdvertisement, MPMoviePlayerController;

@interface STRVideoController : UIViewController

@property (strong, nonatomic, readonly) STRAdvertisement *ad;
@property (strong, nonatomic, readonly) MPMoviePlayerController *moviePlayerController;
@property (weak, nonatomic, readonly) UIView *moviePlayerView;
@property (weak, nonatomic, readonly) UIActivityIndicatorView *spinner;


- (id)initWithAd:(STRAdvertisement *)ad moviePlayerController:(MPMoviePlayerController *)moviePlayerController;

@end
