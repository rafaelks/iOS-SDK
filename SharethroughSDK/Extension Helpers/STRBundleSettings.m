//
//  STRBundleSettings.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/21/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRBundleSettings.h"

@implementation STRBundleSettings

+ (NSBundle *)bundleForResources {
    NSBundle *mainBundle = [NSBundle mainBundle];
    if ([mainBundle pathForResource:@"SharethroughSDK.framework" ofType:nil]) {
        NSString *fullResourcePath = [mainBundle pathForResource:@"SharethroughSDK.framework/Resources/STRResources.bundle" ofType:nil];
        NSBundle *bundle = [NSBundle bundleWithPath:fullResourcePath];

        return bundle;
    }

    return mainBundle;
}

@end
