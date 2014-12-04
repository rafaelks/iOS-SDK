//
//  STRCollectionViewCell.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "STRAdView.h"

@interface STRCollectionViewCell : UICollectionViewCell<STRAdView>

@property (strong, nonatomic) UILabel *adTitle;
@property (strong, nonatomic) UIImageView *adThumbnail;
@property (strong, nonatomic) UILabel *adSponsoredBy;
@property (strong, nonatomic) UIButton *disclosureButton;

@end
