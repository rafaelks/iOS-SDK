//
//  STRYouTubeViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRYouTubeViewController.h"
#import "STRBundleSettings.h"

@interface STRYouTubeViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) STRAdYouTube *ad;

@end

@implementation STRYouTubeViewController

- (id)initWithAd:(STRAdYouTube *)ad {
    self = [super initWithNibName:nil bundle:[STRBundleSettings bundleForResources]];
    if (self) {
        self.ad = ad;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

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

#pragma mark - private

- (void)resizeEmbed {
    CGSize size = CGSizeApplyAffineTransform(self.view.frame.size, self.view.transform);

    NSString *jsString = [NSString stringWithFormat:@"var elem = document.getElementById('player'); elem.width = %0.f; elem.height = %0.f", fabs(size.width), fabs(size.height)];
    [self.webView stringByEvaluatingJavaScriptFromString:jsString];
}

@end
