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

@interface STRAdvertisement ()

@property (strong, nonatomic) STRViewTracker *viewTracker;

@end

@implementation STRAdvertisement

- (id)init {
    if (self = [super init]){
        self.adserverRequestId = @"";
        self.auctionWinId = @"";
    }
    return self;
}

- (id)initWithInjector:(STRInjector *)injector {
    if (self = [super init]) {
        self.injector = injector;
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

- (NSURL *)optOutUrl {
    NSString *privacyUrlString = @"http://platform-cdn.sharethrough.com/privacy-policy.html";
    if (self.optOutUrlString.length > 0) {
        NSString *escapedOptOutUrl = [self.optOutUrlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *escapedOptOutText = [self.optOutText stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        privacyUrlString = [[NSString alloc] initWithFormat:@"http://platform-cdn.sharethrough.com/privacy-policy.html?opt_out_url=%@&opt_out_text=%@", escapedOptOutUrl, escapedOptOutText];
    }
    return [NSURL URLWithString:privacyUrlString];
}

- (void)setThumbnailImageInView:(UIImageView *)imageView {
    imageView.image = self.thumbnailImage;
}

- (UIViewController*) viewControllerForPresentingOnTap {
    return [[STRInteractiveAdViewController alloc] initWithAd:self
                                                       device:[UIDevice currentDevice]
                                                  application:[UIApplication sharedApplication]
                                                beaconService:[self.injector getInstance:[STRBeaconService class]]
                                                     injector:self.injector];
}


- (void)adWasRenderedInView:(UIView *)view {
    STRBeaconService *beaconService = [self.injector getInstance:[STRBeaconService class]];
    if ([beaconService fireImpressionForAd:self adSize:view.frame.size]) {
        [beaconService fireThirdPartyBeacons:self.thirdPartyBeaconsForImpression forPlacementWithStatus:self.placementStatus];
    }
}


#pragma mark - View Tracker

- (void)registerViewForInteraction:(UIView *)view withViewController:(UIViewController *)viewController {
    self.viewTracker = [[STRViewTracker alloc] initWithInjector:self.injector];
    [self.viewTracker trackAd:self inView:view withViewContorller:viewController];
}

+ (void)unregisterView:(UIView *)view {
    [STRViewTracker unregisterView:view];
}

- (void)addDiclosureTapRecognizerToView:(UIView *)view {
    [self.viewTracker addDiclosureTapRecognizerToView:view];
}

//These two methods are a side effect of instant play and should not be called on any ad that is not instant play
//Small compile time trade off instead of reflecting on the class and casting to that class all the time
- (BOOL)adVisibleInView:(UIView *)view {
    return NO;
}

- (BOOL)adNotVisibleInView:(UIView *)view {
    return NO;
}

@end
