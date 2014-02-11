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
    return [self imageWithBytes:kSTRPlayBtn.bytes length:kSTRPlayBtn.length];
}

+ (UIImage *)vineImage {
    return [self imageWithBytes:kSTRVineLogo.bytes length:kSTRVineLogo.length];
}

+ (UIImage *)imageWithBytes:(char *)bytes length:(NSUInteger)length {
    return [UIImage imageWithData:[NSData dataWithBytes:bytes length:length]];
}

@end
