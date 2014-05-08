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
#import "STRAdPinterest.h"
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

    UIView *headerView = [self headerView];
    [self.view addSubview:headerView];

    UIView *contentView = [UIView new];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:contentView];
    self.contentView = contentView;

    [self addAdDisplayChildController:contentView];

    id topGuide = self.topLayoutGuide;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topGuide]-[headerView(==45)]-0-[contentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(topGuide, headerView, contentView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(headerView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(contentView)]];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
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

#pragma mark - Private

- (UIView *)headerView {
    UIView *headerView = [UIView new];

    headerView.backgroundColor = [UIColor blackColor];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *adInfoHeader = [UILabel new];
    NSString *adInfoText = [NSString stringWithFormat:@"%@ %@", self.ad.title, self.ad.sponsoredBy];
    UIFont *lightFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:adInfoHeader.font.pointSize];
    NSMutableAttributedString *attributedAdInfoText = [[NSMutableAttributedString alloc] initWithString:adInfoText attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: lightFont}];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:adInfoHeader.font.pointSize];

    [attributedAdInfoText setAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: boldFont} range:NSMakeRange(0, [self.ad.title length])];

    adInfoHeader.attributedText = attributedAdInfoText;
    adInfoHeader.translatesAutoresizingMaskIntoConstraints = NO;
    self.adInfoHeader = adInfoHeader;
    [headerView addSubview:adInfoHeader];

    UIToolbar *toolbar = [self toolbar];
    [headerView addSubview:toolbar];
    NSNumber *toolbarWidth = @(121.0);
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[adInfoHeader]-[toolbar(==toolbarWidth)]|"
                                                                       options:NSLayoutFormatAlignAllCenterY
                                                                       metrics:NSDictionaryOfVariableBindings(toolbarWidth)
                                                                         views:NSDictionaryOfVariableBindings(adInfoHeader, toolbar)]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[toolbar]|"
                                                                       options:0
                                                                       metrics:nil
                                                                         views:NSDictionaryOfVariableBindings(toolbar)]];

    return headerView;
}

- (UIToolbar *)toolbar {
    UIToolbar *toolbar = [UIToolbar new];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;


    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    UIBarButtonItem *buttonSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    buttonSpacer.width = 15.0;
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)];

    self.doneButton = doneButton;
    self.shareButton = shareButton;

    toolbar.items = @[shareButton, buttonSpacer, doneButton];
    toolbar.barTintColor = [UIColor clearColor];
    toolbar.translucent = NO;
    toolbar.tintColor = [UIColor lightGrayColor];

    return toolbar;
}

- (void)addAdDisplayChildController:(UIView *)contentView {
    UIViewController *childViewController;
    if ([self.ad isKindOfClass:[STRAdYouTube class]]) {
        childViewController = [[STRYouTubeViewController alloc] initWithAd:(STRAdYouTube *)self.ad];
    } else if ([self.ad.action isEqualToString:STRClickoutAd] || [self.ad.action isEqualToString:STRPinterestAd]) {
        childViewController = [[STRClickoutViewController alloc] initWithAd:self.ad];
    } else {
        childViewController = [[STRVideoController alloc] initWithAd:self.ad moviePlayerController:[self.injector getInstance:[MPMoviePlayerController class]]];
    }

    [self addChildViewController:childViewController];
    [childViewController didMoveToParentViewController:self];

    UIView *childView = childViewController.view;
    childView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:childView];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(childView)]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:NSDictionaryOfVariableBindings(childView)]];
}
@end
