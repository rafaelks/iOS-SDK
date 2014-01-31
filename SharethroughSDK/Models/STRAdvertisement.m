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

- (UIImage *)displayableThumbnail {
    NSString *filePath = [[STRBundleSettings bundleForResources] pathForResource:[self centerImageFileName] ofType:nil];
    UIImage *centerImage = [UIImage imageWithContentsOfFile:filePath];

    CGSize size = self.thumbnailImage.size;

    UIGraphicsBeginImageContext(size);
    [self.thumbnailImage drawAtPoint:CGPointMake(0.0, 0.0)];

    CGFloat diameter = ceilf(fminf(size.width, size.height) * 0.3);
    CGFloat leftInset = fmaxf(ceilf((size.width - diameter) * 0.5), 0);
    CGFloat topInset = fmaxf(ceilf((size.height - diameter) * 0.5), 0);
    [centerImage drawInRect:CGRectMake(leftInset, topInset, diameter, diameter)];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (NSString *)centerImageFileName {
    return @"play-btn-300x.png";
}

@end
