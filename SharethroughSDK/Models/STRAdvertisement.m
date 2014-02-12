//
//  STRAdvertisement.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"
#import "STRImages.h"

@implementation STRAdvertisement

- (NSString *)sponsoredBy {
    return [NSString stringWithFormat:@"Promoted by %@", self.advertiser];
}

- (UIImage *)displayableThumbnail {
    CGSize size = self.thumbnailImage.size;

    UIGraphicsBeginImageContext(size);
    [self.thumbnailImage drawAtPoint:CGPointMake(0.0, 0.0)];

    CGFloat diameter = ceilf(fminf(size.width, size.height) * 0.15);
    CGFloat leftInset = fmaxf(ceilf((size.width - diameter) * 0.5), 0);
    CGFloat topInset = fmaxf(ceilf((size.height - diameter) * 0.5), 0);
    [[self centerImage] drawInRect:CGRectMake(leftInset, topInset, diameter, diameter)];

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (UIImage *)centerImage {
    return [STRImages playBtn];
}

@end
