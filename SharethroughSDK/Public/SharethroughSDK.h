//
//  SharethroughSDK.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRAdView.h"

/**
 SharethroughSDK is the main interface to placing ads. There is a shared instance that can be accessed by [SharethroughSDK sharedInstance] which needs to be configured upon first use. Configuration is done through configureWithPriceKey:isStaging: which has more details there. After configuring it, the sharedInstance can be used to place ads, most commonly through placeAdInView:placementKey:.
 */
@interface SharethroughSDK : NSObject

/**
 A readonly property to determine if the Ad generator is running against staging. This value is set by the class constructor generatorWithPriceKey:isStaging:or production.
 */
@property (nonatomic, assign, readonly, getter = isStaging) BOOL staging;

/**
 The accessor for the SDK's shared instance.
 */
+ (instancetype)sharedInstance;

/**
 Configure the shared instance to use the staging or production ad server. Configuration must be done at the beggining of your application's lifecycle, before using the shared instance for displaying ads.
 @param staging Whether to point to the staging ad service or production. YES indicates the staging servers.
 */
- (void)configureWithStaging:(BOOL)staging;

/**
 After creating a custom ad view that adheres to the STRAdView protocol and looks like the rest of your content, you can pass that view to placeAdInView to add the ad details.
 @param view The view to place ad data onto
 @param placementKey The unique identifier for the ad slot
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 @warning If you are placing the ad in a view returned by UITableView/UICollectionView's dequeue method (or any similar reuse mechanism), it is important that you register separate reuse identifier than your normal content cells. Using the same reuse identifier will result in artifacts left behind on content cells (such as ad interactivity behavior).
  */
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController;

/**
 If your app is using a basic UITableView that you want to present ads within, you may alternately use the following method to insert an ad. It is required that the reuse identifier be registered with the UITableView to return a UITableViewCell (or subclass) that conforms to the STRAdView protocol. This reuse identifier should be separate from the reuse identifier used for your content cells, even if they are registered with the same class or xib. A good place to call this function would be -viewDidLoad.
 @param tableView The table view to inject an advertisement
 @param adCellReuseIdentifier The reuse identifier to use whenever displaying an ad cell; the reuse identifier must be registered with the table view with a cell that conforms to the STRAdView protocol
 @param placementKey The unique identifier for the ad to show
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 */
- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController;


@end
