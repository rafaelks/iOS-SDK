//
//  STRAdvertisement.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdvertisement.h"
#import "STRBundleSettings.h"

@implementation STRAdvertisement

- (NSString *)sponsoredBy {
    return [NSString stringWithFormat:@"Promoted by %@", self.advertiser];
}

- (NSString *)youtubeVideoId {
    NSArray *parameters = [[self.mediaURL query] componentsSeparatedByString:@"&"];
    for (NSString *paramSet in parameters) {
        NSArray *tuple = [paramSet componentsSeparatedByString:@"="];
        if ([[tuple firstObject]  isEqual: @"v"]) {
            return [tuple lastObject];
        }
    }
    return nil;
}

@end
