//
//  STRAdYouTube.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/31/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdYouTube.h"

@implementation STRAdYouTube

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
