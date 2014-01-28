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
    if ([self isRunningInFramework]) {
        NSString *fullResourcePath = [mainBundle pathForResource:@"Sharethrough-SDK.framework/Resources/STRResources.bundle" ofType:nil];
        NSBundle *bundle = [NSBundle bundleWithPath:fullResourcePath];

        return bundle;
    }

    return mainBundle;
}

+ (BOOL)isRunningInFramework {
    return !![[NSBundle mainBundle] pathForResource:@"Sharethrough-SDK.framework" ofType:nil];
}

@end
