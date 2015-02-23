//
//  STRImages.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/11/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRImages.h"
#import "images.h"


@implementation STRImages

+ (UIImage *)playBtn {
    return [self imageWithBytes:kSTRPlayBtn.bytes length:kSTRPlayBtn.length atScale:1.0];
}

+ (UIImage *)vineImage {
    return [self imageWithBytes:kSTRVineLogo.bytes length:kSTRVineLogo.length atScale:1.0];
}

+ (UIImage *)pinterestImage {
    return [self imageWithBytes:kSTRPinterestLogo.bytes length:kSTRPinterestLogo.length atScale:1.0];
}

+ (UIImage *)youtubeImage {
    return [self imageWithBytes:kSTRYouTubeLogo.bytes length:kSTRYouTubeLogo.length atScale:1.0];
}

+ (UIImage *)instagramImage {
    return [self imageWithBytes:kSTRInstagramLogo.bytes length:kSTRInstagramLogo.length atScale:1.0];
}

+ (UIImage *)closeImage {
    return [self imageWithBytes:kSTRCloseBtn.bytes length:kSTRCloseBtn.length atScale:2.0];
}

+ (UIImage *)linkImage {
    return [self imageWithBytes:kSTRLinkThumbnail.bytes length:kSTRLinkThumbnail.length atScale:2.0];
}

+ (UIImage *)imageWithBytes:(char *)bytes length:(NSUInteger)length atScale:(CGFloat)scale{
    return [UIImage imageWithData:[NSData dataWithBytes:bytes length:length] scale:scale];
}

@end
