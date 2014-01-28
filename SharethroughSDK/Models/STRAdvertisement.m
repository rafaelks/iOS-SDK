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

    CGPoint upperLeftCorner = CGPointMake(ceilf(0.5 * (size.width - playButton.size.width)), ceilf(0.5 * (size.height - playButton.size.height)));
    [playButton drawAtPoint:upperLeftCorner];

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
