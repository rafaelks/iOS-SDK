//
//  STRTableViewCellFixture.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTableViewCellFixture.h"

@implementation STRTableViewCellFixture

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UILabel *adSponsoredBy = [UILabel new];
        [self addSubview:adSponsoredBy];
        self.adSponsoredBy = adSponsoredBy;
    }
    return self;
}

- (UILabel *)adTitle {
    return self.textLabel;
}

- (UIImageView *)adThumbnail {
    return self.imageView;
}


@end
