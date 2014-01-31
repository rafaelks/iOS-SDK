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

@interface STRInteractiveAdViewController ()<UIWebViewDelegate>

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (weak, nonatomic) UIDevice *device;
@property (weak, nonatomic) STRBeaconService *beaconService;
@property (strong, nonatomic, readwrite) UIPopoverController *sharePopoverController;

@end

@implementation STRInteractiveAdViewController

- (id)initWithAd:(STRAdvertisement *)ad
        device:(UIDevice *)device
    beaconService:(STRBeaconService *)beaconService{
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

    self.webView.scrollView.alwaysBounceHorizontal = NO;
    self.webView.allowsInlineMediaPlayback = YES;
    self.webView.mediaPlaybackRequiresUserAction = NO;

    NSString *htmlPath = [[STRBundleSettings bundleForResources] pathForResource:@"youtube_embed.html" ofType:nil];
    NSString *templateString = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSString *htmlString = [NSString stringWithFormat:templateString, [(STRAdYouTube *)self.ad youtubeVideoId]];

    self.webView.delegate = self;

    NSURL *baseUrl = [NSURL URLWithString:@"http://example.com"];

    [self.webView loadHTMLString:htmlString baseURL:baseUrl];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self resizeEmbed];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.spinner removeFromSuperview];
    [self resizeEmbed];
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

#pragma mark - private 

- (void)resizeEmbed {
    CGSize size = CGSizeApplyAffineTransform(self.contentView.frame.size, self.contentView.transform);

    NSString *jsString = [NSString stringWithFormat:@"var elem = document.getElementById('player'); elem.width = %0.f; elem.height = %0.f", fabs(size.width), fabs(size.height)];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

@end
