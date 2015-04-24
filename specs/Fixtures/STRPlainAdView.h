//
//  STRPlainAdView.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/27/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRAdView.h"

@interface STRPlainAdView : UIView<STRAdView>

@property (weak, nonatomic) UILabel *adTitle;
@property (weak, nonatomic) UILabel *adSponsoredBy;
@property (weak, nonatomic) UIImageView *adThumbnail;
@property (weak, nonatomic) UIButton *disclosureButton;

- (CGFloat)percentVisible;

@end
