//
//  STRYouTubeViewController.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRAdYouTube.h"

@interface STRYouTubeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

- (id)initWithAd:(STRAdYouTube *)ad;

@end
