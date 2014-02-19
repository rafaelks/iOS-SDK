//
//  STRAdvertisement.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STRAdvertisement : NSObject

@property (nonatomic, copy) NSString *advertiser;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *adDescription;
@property (nonatomic, copy) NSString *placementKey;
@property (nonatomic, copy) NSString *creativeKey;
@property (nonatomic, copy) NSString *variantKey;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, copy) NSString *auctionType;
@property (nonatomic, copy) NSString *auctionPrice;
@property (nonatomic, copy) NSURL *mediaURL;
@property (nonatomic, copy) NSURL *shareURL;
@property (nonatomic, strong) UIImage *thumbnailImage;

@property (nonatomic, copy) NSArray *thirdPartyBeaconsForVisibility;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForClick;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForPlay;
@property (nonatomic, assign) BOOL impressionBeaconFired;
@property (nonatomic, assign) BOOL visibleImpressionBeaconFired;

- (NSString *)sponsoredBy;
- (UIImage *)displayableThumbnail;

@end
