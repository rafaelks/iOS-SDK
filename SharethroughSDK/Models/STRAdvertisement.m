//
//  STRAdvertisement.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"
#import "STRImages.h"

NSString *STRYouTubeAd = @"video";
NSString *STRVineAd = @"vine";
NSString *STRClickoutAd = @"clickout";
NSString *STRHostedVideoAd = @"hosted-video";
NSString *STRPinterestAd = @"pinterest";
NSString *STRInstagramAd = @"instagram";

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

@end
