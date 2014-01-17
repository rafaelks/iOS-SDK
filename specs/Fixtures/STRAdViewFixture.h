//
//  STRAdViewFixture.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRAdView.h"

@interface STRAdViewFixture : UIView<STRAdView>

@property (weak, nonatomic) UILabel *adTitle;
@property (weak, nonatomic) UILabel *adDescription;
@property (weak, nonatomic) UIImageView *adThumbnail;

@end