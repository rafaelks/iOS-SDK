//
//  STRTableViewCell.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRAdView.h"

@interface STRTableViewCell : UITableViewCell<STRAdView>

@property (weak, nonatomic) UILabel *adSponsoredBy;

@end
