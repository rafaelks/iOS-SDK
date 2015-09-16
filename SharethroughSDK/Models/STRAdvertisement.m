//
//  STRAdvertisement.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"
#import "STRImages.h"
#import "STRViewTracker.h"
#import "STRInteractiveAdViewController.h"
#import "STRInjector.h"
#import "STRBeaconService.h"

NSString *STRYouTubeAd = @"video";
NSString *STRVineAd = @"vine";
NSString *STRClickoutAd = @"clickout";
NSString *STRHostedVideoAd = @"hosted-video";
NSString *STRPinterestAd = @"pinterest";
NSString *STRInstagramAd = @"instagram";
NSString *STRArticleAd = @"article";

@implementation STRAdvertisement

- (id)init {
    if (self = [super init]){
        self.adserverRequestId = @"";
        self.auctionWinId = @"";
    }
    return self;
}

- (NSString *)sponsoredBy {
    if ([self.promotedByText length] > 0) {
        return [NSString stringWithFormat:@"%@ %@", self.promotedByText, self.advertiser];
    } else {
        return [NSString stringWithFormat:@"Promoted by %@", self.advertiser];
    }
}

- (UIImage *)displayableThumbnail {
    return  self.thumbnailImage;
}

//The name center image is out of date, but this is the platform logo now
- (UIImage *)centerImage {
    return [STRImages playBtn];
}

- (UIImageView *)platformLogoForWidth:(CGFloat)width {
    UIImage *logo = [self centerImage];
    UIImageView *platformLogoView = [[UIImageView alloc] initWithImage:logo];
    CGFloat size = fminf(ceilf(width * 0.25), logo.size.width/2);
    size = fmaxf(size, 24);
    platformLogoView.frame = CGRectMake(0, 0, size, size);

    return platformLogoView;
}

- (void)setThumbnailImageInView:(UIImageView *)imageView {
    imageView.image = self.thumbnailImage;
}

- (UIViewController*) viewControllerForPresentingOnTapWithInjector:(STRInjector *)injector {
    return [[STRInteractiveAdViewController alloc] initWithAd:self
                                                       device:[UIDevice currentDevice]
                                                  application:[UIApplication sharedApplication]
                                                beaconService:[injector getInstance:[STRBeaconService class]]
                                                     injector:injector];
}


#pragma mark - View Tracker

- (void)registerViewForInteraction:(UIView *)view withViewController:(UIViewController *)viewController {
    STRViewTracker *viewTracker = [[STRViewTracker alloc] initWithInjector:self.injector];
    [viewTracker trackAd:self inView:view withViewContorller:viewController];
}

- (void)unregisterView:(UIView *)view {
    [STRViewTracker unregisterView:view];
}

- (BOOL)adVisibleInView:(UIView *)view {
    return NO;
}

- (BOOL)adNotVisibleInView:(UIView *)view {
    return NO;
}

@end
