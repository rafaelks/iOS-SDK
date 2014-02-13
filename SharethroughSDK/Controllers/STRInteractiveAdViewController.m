//
//  STRInteractiveAdViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/21/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRInteractiveAdViewController.h"
#import "STRAdvertisement.h"
#import "STRBeaconService.h"
#import "STRAdYouTube.h"
#import "STRYouTubeViewController.h"
#import "STRAdVine.h"
#import "STRVideoController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "STRInjector.h"
#import "STRClickoutViewController.h"

@interface STRInteractiveAdViewController () 

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (weak, nonatomic) STRBeaconService *beaconService;
@property (weak, nonatomic) STRInjector *injector;
@property (weak, nonatomic) UIDevice *device;
@property (strong, nonatomic, readwrite) UIPopoverController *sharePopoverController;

@end

@implementation STRInteractiveAdViewController

- (id)initWithAd:(STRAdvertisement *)ad device:(UIDevice *)device beaconService:(STRBeaconService *)beaconService injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.ad = ad;
        self.device = device;
        self.beaconService = beaconService;
        self.injector = injector;
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)];

    self.navigationItem.leftBarButtonItem = doneButton;
    self.navigationItem.rightBarButtonItem = shareButton;

    self.doneButton = doneButton;
    self.shareButton = shareButton;

    self.automaticallyAdjustsScrollViewInsets = NO;

    UIView *contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];
    self.contentView = contentView;

    id topGuide = self.topLayoutGuide;

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[contentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(topGuide, contentView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(contentView)]];


    UIViewController *childViewController;
    if ([self.ad isKindOfClass:[STRAdYouTube class]]) {
        childViewController = [[STRYouTubeViewController alloc] initWithAd:(STRAdYouTube *)self.ad];
    } else if ([self.ad.action isEqualToString:@"clickout"]) {
        childViewController = [[STRClickoutViewController alloc] initWithAd:self.ad];
    } else {
        childViewController = [[STRVideoController alloc] initWithAd:self.ad moviePlayerController:[self.injector getInstance:[MPMoviePlayerController class]]];
    }

    [self addChildViewController:childViewController];
    [childViewController didMoveToParentViewController:self];

    UIView *childView = childViewController.view;
    childView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:childView];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(childView)]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(childView)]];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if ([self.ad.action isEqualToString:@"video"] || [self.ad.action isEqualToString:@"hosted-video"]) {
        return UIInterfaceOrientationLandscapeRight;
    } else {
        return self.interfaceOrientation;
    }
}

#pragma mark - Actions

- (void)doneButtonPressed:(id)sender {
    [self.sharePopoverController dismissPopoverAnimated:NO];
    [self.delegate closedInteractiveAdView:self];
}

- (void)shareButtonPressed:(id)sender {
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[self.ad.title, [self.ad.shareURL absoluteString]] applicationActivities:nil];
    activityController.excludedActivityTypes = @[
                                                 UIActivityTypePostToWeibo,
                                                 UIActivityTypePrint,
                                                 UIActivityTypeAssignToContact,
                                                 UIActivityTypeSaveToCameraRoll,
                                                 UIActivityTypeAddToReadingList,
                                                 UIActivityTypePostToFlickr,
                                                 UIActivityTypePostToVimeo,
                                                 UIActivityTypePostToTencentWeibo,
                                                 UIActivityTypeAirDrop,
                                                 ];

    activityController.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (activityType) {
            [self.beaconService fireShareForAd:self.ad shareType:activityType];
        }
    };

    if ([self.device userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (!self.sharePopoverController) {
            self.sharePopoverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        }

        [self.sharePopoverController presentPopoverFromBarButtonItem:self.shareButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:activityController animated:YES completion:nil];
    }
}

@end
