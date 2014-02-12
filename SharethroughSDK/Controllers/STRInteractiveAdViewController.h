//
//  STRInteractiveAdViewController.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/21/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STRAdvertisement, STRBeaconService, STRInjector;
@protocol STRInteractiveAdViewControllerDelegate;

@interface STRInteractiveAdViewController : UIViewController

@property (strong, nonatomic, readonly) STRAdvertisement *ad;
@property (weak, nonatomic) id<STRInteractiveAdViewControllerDelegate> delegate;

@property (weak, nonatomic) UIView *contentView;
@property (weak, nonatomic) UIBarButtonItem *doneButton;
@property (weak, nonatomic) UIBarButtonItem *shareButton;

@property (strong, nonatomic, readonly) UIPopoverController *sharePopoverController;

- (id)initWithAd:(STRAdvertisement *)ad device:(UIDevice *)device beaconService:(STRBeaconService *)beaconService injector:(STRInjector *)injector;
- (void)doneButtonPressed:(id)sender;
- (void)shareButtonPressed:(id)sender;

@end

@protocol STRInteractiveAdViewControllerDelegate <NSObject>

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController;

@end
