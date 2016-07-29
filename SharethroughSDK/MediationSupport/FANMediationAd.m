//
//  FANMediationAd.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 7/27/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "FANMediationAd.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface FANMediationAd()

@property (nonatomic, readonly) FBNativeAd *fbNativeAd;
@property (nonatomic, readonly) FBAdChoicesView *adChoicesView;
@property (nonatomic, readonly) FBMediaView *mediaView;

@end

@implementation FANMediationAd

- (id)initWithFBNativeAd:(FBNativeAd *)nativeAd {
//    strAd.advertiser = nativeAd.?
    self.fbNativeAd = nativeAd;
    self.title = nativeAd.title;
    self.adDescription = nativeAd.body;
}


- (void)setThumbnailImageInView:(UIImageView *)imageView {
    _mediaView = [[FBMediaView alloc] initWithNativeAd:_fbNativeAd];
    [imageView addSubview:_mediaView];
}

@end
