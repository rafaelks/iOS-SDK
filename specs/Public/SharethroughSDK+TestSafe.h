//
//  SharethroughSDK+Fake.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 8/5/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "SharethroughSDK.h"

@interface SharethroughSDK (TestSafeInstance)

/**---------------------------------------------------------------------------------------
 * @name TestSafeInstance
 *  ---------------------------------------------------------------------------------------
 */

typedef NS_ENUM(NSInteger, STRFakeAdType) {
    STRFakeAdTypeYoutube,
    STRFakeAdTypeVine,
    STRFakeAdTypeHostedVideo,
    STRFakeAdTypeInstantPlayVideo,
    STRFakeAdTypeClickout,
    STRFakeAdTypePinterest,
    STRFakeAdTypeInstagram
};

/**
 Creates a SharethroughSDK object that is safe for testing. It is strongly recommended that you use this method (instead of a fake/mock/real sharedInstance) when testing your app. This returns an SDK object which emulates all the behavior of a sharedInstance, but does not perform network activity. It will place the same ad in all views. This is not a singleton.

 @param adType The enum value of the ad requested
 @return a fake instance of a SharethroughSDK, can be used to place fake ads
 */
+ (instancetype)sharedTestSafeInstanceWithAdType:(STRFakeAdType)adType;

@end
