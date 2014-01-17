//
//  STRAdViewFixture.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdViewFixture.h"

@implementation STRAdViewFixture

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *adTitle = [UILabel new];
        self.adTitle = adTitle;
        [self addSubview:adTitle];

        UILabel *adDescription = [UILabel new];
        self.adDescription = adDescription;
        [self addSubview:adDescription];

        UIImageView *adThumbnail = [UIImageView new];
        self.adThumbnail = adThumbnail;
        [self addSubview:adThumbnail];
    }

    return self;
}

@end
