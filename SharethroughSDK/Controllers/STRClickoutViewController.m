//
//  STRClickoutViewController.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/13/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRClickoutViewController.h"
#import "STRAdvertisement.h"
#import "STRLogging.h"

@interface STRClickoutViewController ()

@property (strong, nonatomic, readwrite) STRAdvertisement *ad;
@property (strong, nonatomic, readwrite) UIWebView *webview;

@end

@implementation STRClickoutViewController

- (id)initWithAd:(STRAdvertisement *)ad {
    self = [super init];
    if (self) {
        self.ad = ad;
    }
    return self;
}

- (void)viewDidLoad {
    TLog(@"");
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webview = webView;
    self.webview.scalesPageToFit = YES;
    [webView loadRequest:[NSURLRequest requestWithURL:self.ad.mediaURL]];
    [self.view addSubview:webView];

    webView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
}

@end
