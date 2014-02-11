//
//  STRYouTubeViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRYouTubeViewController.h"
#import "STRBundleSettings.h"
#import "STRAdYouTube.h"
#import "STRYouTubeEmbedPage.h"

@interface STRYouTubeViewController ()<UIWebViewDelegate>

@property (nonatomic, strong, readwrite) STRAdYouTube *ad;

@end

@implementation STRYouTubeViewController

- (id)initWithAd:(STRAdYouTube *)ad {
    self = [super init];
    if (self) {
        self.ad = ad;
    }
    return self;
}

- (void)loadView {
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
    [super viewDidLoad];

    [self.spinner startAnimating];

    self.webView.scrollView.alwaysBounceHorizontal = NO;
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

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.spinner removeFromSuperview];
    [self resizeEmbed];
}

#pragma mark - private

- (void)resizeEmbed {
    CGSize size = CGSizeApplyAffineTransform(self.view.frame.size, self.view.transform);

    NSString *jsString = [NSString stringWithFormat:@"var elem = document.getElementById('player'); elem.width = %0.f; elem.height = %0.f", fabs(size.width), fabs(size.height)];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

@end
