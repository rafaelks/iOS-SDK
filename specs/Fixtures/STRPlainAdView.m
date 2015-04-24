//
//  STRPlainAdView.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/27/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRPlainAdView.h"

@implementation STRPlainAdView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *adTitle = [UILabel new];
        adTitle.text = @"title text";
        self.adTitle = adTitle;
        [self addSubview:adTitle];

        UILabel *adSponsoredBy = [UILabel new];
        adSponsoredBy.text = @"Sponsored by fixtures";
        self.adSponsoredBy = adSponsoredBy;
        [self addSubview:adSponsoredBy];

        UIImageView *adThumbnail = [UIImageView new];
        self.adThumbnail = adThumbnail;
        [self addSubview:adThumbnail];
        
        UIButton *disclouseButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        self.disclosureButton = disclouseButton;
        [self addSubview:disclouseButton];
    }

    return self;
}

- (CGFloat)percentVisible {
    return 0.0f;
}

@end
