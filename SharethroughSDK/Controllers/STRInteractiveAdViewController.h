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
@property (weak, nonatomic) id<STRInteractiveAdViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic, readonly) UIPopoverController *sharePopoverController;

- (id)initWithAd:(STRAdvertisement *)ad device:(UIDevice *)device;
- (IBAction)doneButtonPressed:(id)sender;
- (IBAction)shareButtonPressed:(id)sender;

@end

@protocol STRInteractiveAdViewControllerDelegate <NSObject>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController;

@end