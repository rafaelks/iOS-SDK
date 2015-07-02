//
//  STRClickoutViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/13/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRClickoutViewController.h"

#import "STRAdArticle.h"
#import "STRAdvertisement.h"
#import "STRBeaconService.h"
#import "STRLogging.h"

@interface STRClickoutViewController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (strong, nonatomic, readwrite) UIWebView *webview;
@property (strong, nonatomic, readwrite) NSDate *articleViewStart;
@property (strong, nonatomic, readwrite) NSDate *articleViewEnd;
@property (weak, nonatomic) STRBeaconService *beaconService;

@end

@implementation STRClickoutViewController

- (id)initWithAd:(STRAdvertisement *)ad beaconService:(STRBeaconService *)beaconService {
    self = [super init];
    if (self) {
        self.ad = ad;
        self.beaconService = beaconService;
    }
    return self;
}

- (void)viewDidLoad {
    TLog(@"");
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webview = webView;
    self.webview.delegate = self;
    self.webview.scalesPageToFit = YES;
    [webView loadRequest:[NSURLRequest requestWithURL:self.ad.mediaURL]];
    [self.view addSubview:webView];

    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;

    if ([self.ad isKindOfClass:[STRAdArticle class]]) {
        [self.beaconService fireArticleViewForAd:self.ad];
        [self initArticleTime];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initArticleTime) name:UIApplicationWillEnterForegroundNotification object:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self fireArticleViewDuration];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma Mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (![webView.request.URL.host isEqualToString:self.ad.mediaURL.host]) {
        [self fireArticleViewDuration];
    }
}

#pragma Mark - Private Methods

- (void)initArticleTime {
    self.articleViewStart = [NSDate date];
}

- (void)fireArticleViewDuration {
    if (self.articleViewStart && !self.articleViewEnd) {
        self.articleViewEnd = [NSDate date];
        NSTimeInterval articleViewDuration = [self.articleViewEnd timeIntervalSinceDate:self.articleViewStart];
        [self.beaconService fireArticleDurationForAd:self.ad withDuration:articleViewDuration];
    }
}
@end
