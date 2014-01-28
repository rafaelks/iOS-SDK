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
        UILabel *adDescription = [UILabel new];
        adDescription.text = @"description text";
        self.adDescription = adDescription;
        [self addSubview:adDescription];
    }

    return self;
}

@end
