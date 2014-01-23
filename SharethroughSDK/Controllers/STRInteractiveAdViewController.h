//
//  STRInteractiveAdViewController.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/21/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STRAdvertisement;
@protocol STRInteractiveAdViewControllerDelegate;

@interface STRInteractiveAdViewController : UIViewController

@property (strong, nonatomic, readonly) STRAdvertisement *ad;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) id<STRInteractiveAdViewControllerDelegate> delegate;

- (id)initWithAd:(STRAdvertisement *)ad;
- (IBAction)doneButtonPressed:(id)sender;

@end

@protocol STRInteractiveAdViewControllerDelegate <NSObject>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController;

@end
