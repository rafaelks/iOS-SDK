//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

/**
 This class is the main interface for configuring an ad.
 */

#import <Foundation/Foundation.h>

@protocol STRAdView;

@interface STRAdGenerator : NSObject

/**
 After creating a custom ad view that adheres to the STRAdView protocol and looks like the rest of your content, you can pass that view to placeAdInView to add the ad details.
 @param view The view to place ad data onto
 */
- (void)placeAdInView:(id<STRAdView>)view;

@end
