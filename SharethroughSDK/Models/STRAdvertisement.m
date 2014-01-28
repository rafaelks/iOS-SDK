//
//  STRAdvertisement.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"
#import "STRBundleSettings.h"

@implementation STRAdvertisement

- (NSString *)sponsoredBy {
    return [NSString stringWithFormat:@"Promoted by %@", self.advertiser];
}

- (UIImage *)thumbnailWithPlayImage {
    NSString *playButtonPath = [[STRBundleSettings bundleForResources] pathForResource:@"play-btn.tiff" ofType:nil];
    UIImage *playButton = [UIImage imageWithContentsOfFile:playButtonPath];

    CGSize size = self.thumbnailImage.size;
    UIGraphicsBeginImageContext(size);
    [self.thumbnailImage drawAtPoint:CGPointMake(0.0, 0.0)];

    CGFloat diameter = ceilf(fminf(size.width, size.height) * 0.3);
    CGFloat leftInset = fmaxf(ceilf((size.width - diameter) * 0.5), 0);
    CGFloat topInset = fmaxf(ceilf((size.height - diameter) * 0.5), 0);
    [playButton drawInRect:CGRectMake(leftInset, topInset, diameter, diameter)];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (NSString *)youtubeVideoId {
    NSArray *parameters = [[self.mediaURL query] componentsSeparatedByString:@"&"];
    for (NSString *paramSet in parameters) {
        NSArray *tuple = [paramSet componentsSeparatedByString:@"="];
        if ([[tuple firstObject]  isEqual: @"v"]) {
            return [tuple lastObject];
        }
    }
    return nil;
}

@end
