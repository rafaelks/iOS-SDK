//
//  STRNetworkClient.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRNetworkClient.h"
#import "STRDeferred.h"

@implementation STRNetworkClient

- (STRPromise *)get:(NSURLRequest *)request {

    STRDeferred *deferred = [STRDeferred defer];

    NSString *userAgentString;
    NSString *model = [[UIDevice currentDevice] model];
    if ( [model rangeOfString:@"iPad"].location != NSNotFound) {
        userAgentString = @"iPad; OS like Mac OS X";
    } else if ( [model rangeOfString:@"iPod"].location != NSNotFound) {
        userAgentString = @"iPod/iPhone";
    } else {
        userAgentString = @"iPhone";
    }

    NSMutableURLRequest *requestWithUserAgent = [request mutableCopy];
    [requestWithUserAgent setValue:userAgentString forHTTPHeaderField:@"User-Agent"];

    [NSURLConnection sendAsynchronousRequest:requestWithUserAgent queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            [deferred rejectWithError:connectionError];
        } else {
            [deferred resolveWithValue:data];
        }
    }];

    return deferred.promise;
}

@end
