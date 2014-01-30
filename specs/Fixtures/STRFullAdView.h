//
//  STRFullAdView.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STRAdView.h"
#import "STRPlainAdView.h"

@interface STRFullAdView : STRPlainAdView <STRAdView>

@property (weak, nonatomic) UILabel *adDescription;

@end