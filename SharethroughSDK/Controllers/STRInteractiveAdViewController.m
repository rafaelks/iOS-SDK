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

@interface STRInteractiveAdViewController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;

@end

@implementation STRInteractiveAdViewController

- (id)initWithAd:(STRAdvertisement *)ad {
    self = [super initWithNibName:nil bundle:[STRBundleSettings bundleForResources]];
    if (self) {
        self.ad = ad;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.largePreview.image = self.ad.thumbnailImage;
}

- (IBAction)doneButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
