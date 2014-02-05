//
//  SharethroughSDK.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRAdView.h"
#import "STRAdViewDelegate.h"

/**
 SharethroughSDK is the main interface to placing ads. There is a shared instance that can be accessed by [SharethroughSDK sharedInstance]. It can be used to place ads, most commonly through placeAdInView:placementKey:.
 */
@interface SharethroughSDK : NSObject

/**
 The accessor for the SDK's shared instance.
 */
+ (instancetype)sharedInstance;

/**
 After creating a custom ad view that adheres to the STRAdView protocol and looks like the rest of your content, you can pass that view to placeAdInView to add the ad details.
 @param view The view to place ad data onto
 @param placementKey The unique identifier for the ad slot
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 @param delegate Delegate for handling completion. This can be nil if you do not wish to customize success or failure behavior.
 @warning If you are placing the ad in a view returned by UITableView/UICollectionView's dequeue method (or any similar reuse mechanism), it is important that you register separate reuse identifier than your normal content cells. Using the same reuse identifier will result in artifacts left behind on content cells (such as ad interactivity behavior).
  */
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController delegate:(id<STRAdViewDelegate>)delegate;

/**
 If your app is using a basic UITableView that you want to present ads within, you may alternately use the following method to insert an ad. It is required that the reuse identifier be registered with the UITableView to return a UITableViewCell (or subclass) that conforms to the STRAdView protocol. This reuse identifier should be separate from the reuse identifier used for your content cells, even if they are registered with the same class or xib. A good place to call this function would be -viewDidLoad.
 @param tableView The table view in which to inject an advertisement
 @param adCellReuseIdentifier The reuse identifier to use whenever displaying an ad cell; the reuse identifier must be registered with the table view with a cell that conforms to the STRAdView protocol
 @param placementKey The unique identifier for the ad to show
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 @param adHeight The height of the adCell. This value will be unused if your delegate does not implement -tableView:heightForRowAtIndexPath: (the tableView will use rowHeight instead)
 */
- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight;

/**
 If your app is using a basic UICollectionView that you want to present ads within, you may alternately use the following method to insert an ad. It is required that the reuse identifier be registered with the UIColectionView to return a UICollectionViewCell (or subclass) that conforms to the STRAdView protocol. This reuse identifier should be separate from the reuse identifier used for your content cells, even if they are registered with the same class or xib. A good place to call this function would be -viewDidLoad.

 @param collectionView           The collection view in which to inject an advertisment.
 @param adCellReuseIdentifier    The reuse identifier to use whenever displaying an ad cell; the reuse identifier must be registered with the table view with a cell that conforms to the STRAdView protocol
 @param placementKey             The unique identifier for the ad to show
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 */
- (void)placeAdInCollectionView:(UICollectionView *)collectionView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController;


@end
