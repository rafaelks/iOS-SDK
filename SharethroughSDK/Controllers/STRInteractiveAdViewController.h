//
//  STRInteractiveAdViewController.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/21/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STRAdvertisement;

@interface STRInteractiveAdViewController : UIViewController

@property (strong, nonatomic, readonly) STRAdvertisement *ad;
@property (weak, nonatomic) IBOutlet UIImageView *largePreview;

- (id)initWithAd:(STRAdvertisement *)ad;
- (IBAction)doneButtonPressed:(id)sender;

@end
