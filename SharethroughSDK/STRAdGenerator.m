//
//  STRAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdGenerator.h"
#import "STRAdView.h"

@implementation STRAdGenerator

- (void)placeAdInView:(id <STRAdView>)view {
    view.adTitle.text = @"Ad title, from SDK";
    view.adDescription.text = @"Ad description, from SDK";
    view.adThumbnail.image = [UIImage imageNamed:@"STRResources.bundle/images/fixture_image.png"];
}
@end
