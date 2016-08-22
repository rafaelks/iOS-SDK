//
//  FANNetworkAd.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 8/19/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "FANNetworkAd.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface FANNetworkAd()

@property (nonatomic, strong) FBNativeAd *fbNativeAd;
@property (nonatomic, strong) FBAdChoicesView *adChoicesView;
@property (nonatomic, strong) FBMediaView *mediaView;

@end

@implementation FANNetworkAd

- (id)initWithFBNativeAd:(FBNativeAd *)nativeAd {
    self = [super init];
    if (self) {
        //    strAd.advertiser = nativeAd.?
        self.fbNativeAd = nativeAd;
        self.title = nativeAd.title;
        self.adDescription = nativeAd.body;
    }
    return self;
}

- (void)setThumbnailImageInView:(UIImageView *)imageView {
    _mediaView = [[FBMediaView alloc] initWithNativeAd:_fbNativeAd];
    _mediaView.frame = imageView.frame;
    [imageView addSubview:_mediaView];
}

@end
