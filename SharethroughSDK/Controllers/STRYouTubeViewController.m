//
//  STRYouTubeViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRYouTubeViewController.h"

#import "STRAdYouTube.h"
#import "STRBeaconService.h"
#import "STRYouTubeEmbedPage.h"
#import "STRLogging.h"
#import "STRIneractiveChild.h"

@interface STRYouTubeViewController ()<UIWebViewDelegate>

@property (nonatomic, strong, readwrite) STRAdYouTube *ad;
@property (weak, nonatomic) STRBeaconService *beaconService;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSMutableArray *firedCompletionBeacons;
@property (strong, nonatomic) NSNumber *videoDuration;

@end

@implementation STRYouTubeViewController

- (id)initWithAd:(STRAdYouTube *)ad beaconService:(STRBeaconService *)beaconService {
    self = [super init];
    if (self) {
        self.ad = ad;
        self.beaconService = beaconService;
        self.firedCompletionBeacons = [NSMutableArray arrayWithArray:@[@NO, @NO, @NO, @NO]];
    }
    return self;
}

- (void)loadView {
    TLog(@"");
    UIView *view = [[UIView alloc] initWithFrame:(CGRect){.size.width = 320, .size.height = 568}];
    UIWebView *webview = [[UIWebView alloc] initWithFrame:view.bounds];
    [view addSubview:webview];

    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [view addSubview:spinny];

    webview.translatesAutoresizingMaskIntoConstraints = NO;
    spinny.translatesAutoresizingMaskIntoConstraints = NO;

    NSArray *fitWebviewToWidth = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webview]-0-|"
                                                                         options:0
                                                                         metrics:nil
                                                                           views:NSDictionaryOfVariableBindings(webview)];
    [view addConstraints:fitWebviewToWidth];

    NSArray *fitWebviewToHeight = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webview]-0-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:NSDictionaryOfVariableBindings(webview)];
    [view addConstraints:fitWebviewToHeight];

    NSLayoutConstraint *centerSpinnyHorizontally = [NSLayoutConstraint constraintWithItem:spinny
                                                                                attribute:NSLayoutAttributeCenterX
                                                                                relatedBy:NSLayoutRelationEqual
                                                                                   toItem:view
                                                                                attribute:NSLayoutAttributeCenterX
                                                                               multiplier:1.0 constant:0];
    [view addConstraint:centerSpinnyHorizontally];

    NSLayoutConstraint *centerSpinnyVertically = [NSLayoutConstraint constraintWithItem:spinny
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:view
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0 constant:0];
    [view addConstraint:centerSpinnyVertically];

    self.webView = webview;
    self.spinner = spinny;

    self.view = view;
}

- (void)viewDidLoad {
    TLog(@"");
    [super viewDidLoad];
    [self.spinner startAnimating];

    self.webView.scrollView.scrollEnabled = NO;
    self.webView.allowsInlineMediaPlayback = YES;
    self.webView.mediaPlaybackRequiresUserAction = NO;

    NSString *templateString = [STRYouTubeEmbedPage htmlForYouTubeEmbed];
    NSString *htmlString = [NSString stringWithFormat:templateString, [(STRAdYouTube *)self.ad youtubeVideoId]];

    self.webView.delegate = self;

    NSURL *baseUrl = [NSURL URLWithString:@"http://example.com"];

    [self.webView loadHTMLString:htmlString baseURL:baseUrl];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self resizeEmbed];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.timer invalidate];
    
    [self.webView stringByEvaluatingJavaScriptFromString:@"player.stopVideo();"];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.spinner removeFromSuperview];
    [self resizeEmbed];

    [self.timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireCompletionBeacon) userInfo:nil repeats:YES];
}

#pragma mark - STRInteractiveChild
- (void)cleanupResources {
    TLog(@"");
}

#pragma mark - private

- (void)resizeEmbed {
    CGSize size = CGSizeApplyAffineTransform(self.view.frame.size, self.view.transform);

    NSString *jsString = [NSString stringWithFormat:@"var elem = document.getElementById('player'); elem.width = %0.f; elem.height = %0.f", fabs(size.width), fabs(size.height)];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

- (void)fireCompletionBeacon {
    if (!self.videoDuration) {
        NSString *duration = [self.webView stringByEvaluatingJavaScriptFromString:@"player.getDuration();"];
        if ([duration length] > 0) {
            self.videoDuration = [NSNumber numberWithFloat:[duration floatValue]];
        }
    } else {
        NSString *currentPlaybackTime = [self.webView stringByEvaluatingJavaScriptFromString:@"player.getCurrentTime();"];

        float completionPercent = ([currentPlaybackTime floatValue] / [self.videoDuration floatValue]) * 100;

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
}

@end
