//
//  STRAdvertisement.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STRInjector;
@protocol STRAdvertisementDelegate;

extern NSString *STRYouTubeAd;
extern NSString *STRVineAd;
extern NSString *STRClickoutAd;
extern NSString *STRHostedVideoAd;
extern NSString *STRPinterestAd;
extern NSString *STRInstagramAd;
extern NSString *STRArticleAd;

@interface STRAdvertisement : NSObject

@property (nonatomic, copy) NSString *advertiser;
@property (nonatomic, copy) NSString *action;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *adDescription;
@property (nonatomic, copy) NSString *placementKey;
@property (nonatomic, copy) NSString *placementStatus;
@property (nonatomic, copy) NSString *creativeKey;
@property (nonatomic, copy) NSString *variantKey;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, copy) NSString *auctionType;
@property (nonatomic, copy) NSString *auctionPrice;
@property (nonatomic, copy) NSString *adserverRequestId;
@property (nonatomic, copy) NSString *auctionWinId;
@property (nonatomic, copy) NSString *customEngagementLabel;
@property (nonatomic, copy) NSString *promotedByText;
@property (nonatomic, copy) NSURL *customEngagementURL;
@property (nonatomic, copy) NSURL *mediaURL;
@property (nonatomic, copy) NSURL *shareURL;
@property (nonatomic, copy) NSURL *brandLogoURL;
@property (nonatomic, copy) NSURL *thumbnailURL;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic, strong) UIImage *brandLogoImage;
@property (nonatomic) NSInteger placementIndex;
@property (nonatomic, copy) NSString *dealId;

@property (nonatomic, copy) NSArray *thirdPartyBeaconsForImpression;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForVisibility;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForClick;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForPlay;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForSilentPlay;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForTenSecondSilentPlay;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForFifteenSecondSilentPlay;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForThirtySecondSilentPlay;
@property (nonatomic, copy) NSArray *thirdPartyBeaconsForCompletedSecondSilentPlay;
@property (nonatomic, assign) BOOL   impressionBeaconFired;
@property (nonatomic, assign) BOOL   visibleImpressionBeaconFired;
@property (nonatomic, copy) NSDate  *visibleImpressionTime;

@property (nonatomic, weak) STRInjector *injector;
@property (nonatomic, weak) id<STRAdvertisementDelegate> delegate;

- (id)initWithInjector:(STRInjector *)injector;

- (NSString *)sponsoredBy;
- (UIImage *)displayableThumbnail;
- (UIImageView *)platformLogoForWidth:(CGFloat)width;

- (void)setThumbnailImageInView:(UIImageView *)imageView;

- (UIViewController*) viewControllerForPresentingOnTap;

- (void)adWasRenderedInView:(UIView *)view;
- (void)registerViewForInteraction:(UIView *)view withViewController:(UIViewController *)viewController;
- (void)addDiclosureTapRecognizerToView:(UIView *)view;
+ (void)unregisterView:(UIView *)view;

- (BOOL)adVisibleInView:(UIView *)view;
- (BOOL)adNotVisibleInView:(UIView *)view;
@end
