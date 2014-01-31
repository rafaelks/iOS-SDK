//
//  STRInteractiveAdViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/21/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRInteractiveAdViewController.h"
#import "STRBundleSettings.h"
#import "STRAdvertisement.h"
#import "STRBeaconService.h"
#import "STRAdYouTube.h"
#import "STRYouTubeViewController.h"

@interface STRInteractiveAdViewController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (weak, nonatomic) STRBeaconService *beaconService;
@property (weak, nonatomic) UIDevice *device;
@property (strong, nonatomic, readwrite) UIPopoverController *sharePopoverController;

@end

@implementation STRInteractiveAdViewController

- (id)initWithAd:(STRAdvertisement *)ad device:(UIDevice *)device beaconService:(STRBeaconService *)beaconService {
    self = [super initWithNibName:nil bundle:[STRBundleSettings bundleForResources]];
    if (self) {
        self.ad = ad;
        self.device = device;
        self.beaconService = beaconService;
    }

    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSDictionary *views = @{@"topGuide": self.topLayoutGuide, @"toolbar": self.toolbar};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topGuide]-[toolbar]"
                                                                     options:0
                                                                     metrics:nil
                                                                       views:views]];
    if ([self.ad isKindOfClass:[STRAdYouTube class]]) {
        STRYouTubeViewController *youTubeController = [[STRYouTubeViewController alloc] initWithAd:(STRAdYouTube *)self.ad];
        [youTubeController willMoveToParentViewController:self];
        [self addChildViewController:youTubeController];
        [youTubeController didMoveToParentViewController:self];

        UIView *youTubeView = youTubeController.view;
        youTubeView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:youTubeView];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[youTubeView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(youTubeView)]];
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[youTubeView]|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(youTubeView)]];
    }
}

#pragma mark - Actions

- (IBAction)doneButtonPressed:(id)sender {
    [self.sharePopoverController dismissPopoverAnimated:NO];
    [self.delegate closedInteractiveAdView:self];
}

- (IBAction)shareButtonPressed:(id)sender {
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
