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

    NSString *path;
    if ([self runningInFramework]) {
        path = [[NSBundle mainBundle] pathForResource:@"Sharethrough-SDK.framework/Resources/STRResources.bundle/images/fixture_image.png" ofType:nil];
    } else {
        path = [[NSBundle mainBundle] pathForResource:@"STRResources.bundle/images/fixture_image.png" ofType:nil];
    }

    view.adThumbnail.contentMode = UIViewContentModeScaleAspectFill;
    view.adThumbnail.image = [UIImage imageWithContentsOfFile:path];
}

- (BOOL)runningInFramework {
    return [[NSBundle mainBundle] pathForResource:@"Sharethrough-SDK.framework" ofType:nil] != nil;
}
@end
