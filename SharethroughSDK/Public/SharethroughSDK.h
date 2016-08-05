//
//  SharethroughSDK.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRAdvertisement.h"
#import "STRAdvertisementDelegate.h"
#import "STRAdView.h"
#import "STRAdViewDelegate.h"
#import "UITableView+STR.h"
#import "UICollectionView+STR.h"

/**
 SharethroughSDK is the main interface to placing ads. There is a shared instance that can be accessed by [SharethroughSDK sharedInstance]. It can be used to place ads, most commonly through placeAdInView:placementKey:.
 */
@interface SharethroughSDK : NSObject

/**
 The accessor for the SDK's shared instance.
 */
+ (instancetype)sharedInstance;

/**
 This method allows prefetching of ads for a particular placement key
 @param placementKey The unique identifier for the ad slot
 @param customProperties (Optional) A dictionary of custom properties (such as targeting parameters) to be passed on to the ad server. This value can be nil.
 @param delegate (Optional) Delegate for handling completion. This can be nil if you do not wish to customize success or failure behavior.
 */
- (void)prefetchAdForPlacementKey:(NSString *)placementKey customProperties:(NSDictionary *)customProperties delegate:(id<STRAdViewDelegate>)delegate;

/**
 After creating a custom ad view that adheres to the STRAdView protocol and looks like the rest of your content, you can pass that view to placeAdInView to add the ad details.
 @param view The view to place ad data onto
 @param placementKey The unique identifier for the ad slot
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 @param index The index of the ad if there are multiple ads shown using a single placementKey, i.e. infinite scroll. If only ad is shown for the placementKey, pass 0 every time.
 @param customProperties (Optional) A dictionary of custom properties (such as targeting parameters) to be passed on to the ad server. This value can be nil.
 @param delegate (Optional) Delegate for handling completion. This can be nil if you do not wish to customize success or failure behavior.
 @warning If you are placing the ad in a view returned by UITableView/UICollectionView's dequeue method (or any similar reuse mechanism), it is important that you register separate reuse identifier than your normal content cells. Using the same reuse identifier will result in artifacts left behind on content cells (such as ad interactivity behavior).
  */
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController index:(NSInteger)index customProperties:(NSDictionary *)customProperties delegate:(id<STRAdViewDelegate>)delegate;

/**
 If your app is using a basic UITableView that you want to present ads within, you may alternately use the following method to insert an ad. It is required that the reuse identifier be registered with the UITableView to return a UITableViewCell (or subclass) that conforms to the STRAdView protocol. This reuse identifier should be separate from the reuse identifier used for your content cells, even if they are registered with the same class or xib. A good place to call this function would be -viewDidLoad. Calling this method on the same table view will remove previously existing ad(s) and place an ad at the place specified by adStartingIndexPath.
 @param tableView The table view in which to inject an advertisement
 @param adCellReuseIdentifier The reuse identifier to use whenever displaying an ad cell; the reuse identifier must be registered with the table view with a cell that conforms to the STRAdView protocol
 @param placementKey The unique identifier for the ad to show
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 @param adHeight The height of the adCell. This value will be unused if your delegate does not implement -tableView:heightForRowAtIndexPath: (the tableView will use rowHeight instead)
 @param adSection The section in which the ad will appear
 @param customProperties (Optional) A dictionary of custom properties (such as targeting parameters) to be passed on to the ad server. This value can be nil.
 
 @discussion The UITableView's dataSource methods of –tableView:commitEditingStyle:forRowAtIndexPath:, –tableView:canEditRowAtIndexPath:, –tableView:canMoveRowAtIndexPath:, –tableView:moveRowAtIndexPath:toIndexPath: are curerently not supported. Apps that wish to use these should instead use the more generic -placeAdInView:placementKey:presentingViewController:delegate:
 */
- (void)placeAdInTableView:(UITableView *)tableView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adHeight:(CGFloat)adHeight adSection:(NSInteger)adSection customProperties:(NSDictionary *)customProperties;

/**
 If your app is using a basic UICollectionView that you want to present ads within, you may alternately use the following method to insert an ad. It is required that the reuse identifier be registered with the UIColectionView to return a UICollectionViewCell (or subclass) that conforms to the STRAdView protocol. This reuse identifier should be separate from the reuse identifier used for your content cells, even if they are registered with the same class or xib. A good place to call this function would be -viewDidLoad.
 
 Your collectionView's UICollectionViewLayout must be able to accomdate an ad cell, in addition it its content cells.

 @param collectionView           The collection view in which to inject an advertisment.
 @param adCellReuseIdentifier    The reuse identifier to use whenever displaying an ad cell; the reuse identifier must be registered with the table view with a cell that conforms to the STRAdView protocol
 @param placementKey             The unique identifier for the ad to show
 @param presentingViewController The view controller that will present the interactive ad controller if the user taps on the ad
 @param adSize                   The size of the adCell. This value will only be used if your collectionView delegate is a UICollectionViewDelegateFlowLayout and implements –collectionView:layout:sizeForItemAtIndexPath:
 @param adSection The section in which the ad will appear
 @param customProperties (Optional) A dictionary of custom properties (such as targeting parameters) to be passed on to the ad server. This value can be nil.
 
    This is the only time the index path is computed taking into account the ad position. Future calls to the collection view should use STR's provided category methods (instead of UICollectionView's corresponding built-in methods). In using these category methods, index paths do not need to account for the extra ad cell.
 */
- (void)placeAdInCollectionView:(UICollectionView *)collectionView adCellReuseIdentifier:(NSString *)adCellReuseIdentifier placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController adSize:(CGSize)adSize adSection:(NSInteger)adSection customProperties:(NSDictionary *)customProperties;

/**
 This method can be used to determine if an ad is available.
 @param placementKey The unique identifier for the ad slot
 @param index The index of the ad if there are multiple ads shown using a single placementKey, i.e. infinite scroll. If only ad is shown for the placementKey, pass 0 every time.
 */
- (BOOL)isAdAvailableForPlacement:(NSString *)placementKey atIndex:(NSInteger)index;

/**
 + This method will return the currently assigned ad if one is available.
 + It will return nil if no ad is available at this time.
 + @param placementKey The unique identifier for the ad slot
 + @param index The index of the ad if there are multiple ads shown using a single placementKey, i.e. infinite scroll. If only ad is shown for the placementKey, pass 0 every time.
 + */
- (STRAdvertisement *)AdForPlacement:(NSString *)placementKey atIndex:(NSInteger)index;

/**
 This method can be used to determine the total number of ads available for a placementKey.
 This will include the assigned and unassigned but cached ads.
 @param placementKey The unique identifier for the ad slot
 */
- (NSInteger)totalNumberOfAdsAvailableForPlacement:(NSString *)placementKey;

/**
 This method can be used to determine the number unassigned ads available for a placementKey.
 @param placementKey The unique identifier for the ad slot
 */
- (NSInteger)unassignedNumberOfAdsAvailableForPlacement:(NSString *)placementKey;

/**
 This method will clear the ads currently cached for the placement key
 @param placementKey The unique identifier for the ad slot
 */
- (void)clearCachedAdsForPlacement:(NSString *)placementKey;

@end
