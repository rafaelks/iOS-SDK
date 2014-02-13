//
//  STRClickoutViewController.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/13/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "SharethroughSDK.h"
@class STRAdvertisement;
@interface STRClickoutViewController : UIViewController

@property (strong, nonatomic, readonly) STRAdvertisement *ad;
@property (strong, nonatomic, readonly) UIWebView *webview;

- (id)initWithAd:(STRAdvertisement *)ad;

@end