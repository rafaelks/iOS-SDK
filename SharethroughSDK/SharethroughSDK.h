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
 A read-only property to retrieve the priceKey set by the class constructor generatorWithPriceKey:isStaging:.
 */
@property (nonatomic, assign, readonly) NSString *priceKey;

/**
 The accessor for the SDK's shared instance.
 */
+ (instancetype)sharedInstance;

/**
 Configure the shared instance with a price key and whether to use the staging or production ad server. Configuration should be done at the beggining of your application's lifecycle, before using the shared instance for displaying ads.
 @param priceKey The price key provided when signing up. If you don't have one, please contact support.
 @param staging Whether to point to the staging ad service or production. YES indicates the staging servers.
 */
- (void)configureWithPriceKey:(NSString *)priceKey isStaging:(BOOL)staging;

/**
 After creating a custom ad view that adheres to the STRAdView protocol and looks like the rest of your content, you can pass that view to placeAdInView to add the ad details.
 @param view The view to place ad data onto
 @param placementKey The unique identifier for the ad slot
 */
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey;


@end
