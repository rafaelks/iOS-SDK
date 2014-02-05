//
//  STRCollectionViewCell.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRCollectionViewCell.h"

@implementation STRCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *adSponsoredBy = [UILabel new];
        [self.contentView addSubview:adSponsoredBy];
        self.adSponsoredBy = adSponsoredBy;

        UILabel *titleLabel = [UILabel new];
        [self.contentView addSubview:titleLabel];
        self.adTitle = titleLabel;

        UIImageView *imageView = [UIImageView new];
        [self.contentView addSubview:imageView];
        self.adThumbnail = imageView;
    }
    
    return self;
}

@end
