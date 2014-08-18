//
//  STRNetworkClient.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRVersion.h"

@implementation STRNetworkClient {
    NSMutableString *userAgentString;
}

- (STRPromise *)get:(NSURLRequest *)request {

    STRDeferred *deferred = [STRDeferred defer];

    NSMutableURLRequest *requestWithUserAgent = [request mutableCopy];
    [requestWithUserAgent setValue:[self userAgent] forHTTPHeaderField:@"User-Agent"];

    [NSURLConnection sendAsynchronousRequest:requestWithUserAgent queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            [deferred rejectWithError:connectionError];
        } else {
            [deferred resolveWithValue:data];
        }
    }];

    return deferred.promise;
}
    
- (NSString *)userAgent {
    if (userAgentString) {
        return userAgentString;
    }
    
    userAgentString = [NSMutableString stringWithCapacity:40];
    
    NSString *model = [[UIDevice currentDevice] model];
    if ( [model rangeOfString:@"iPad"].location != NSNotFound) {
        [userAgentString appendString:@"iPad; OS like Mac OS X"];
    } else if ( [model rangeOfString:@"iPod"].location != NSNotFound) {
        [userAgentString appendString:@"iPod/iPhone"];
    } else {
        [userAgentString appendString:@"iPhone"];
    }
    
    [userAgentString appendFormat:@"; iOS %@", [[UIDevice currentDevice] systemVersion]];
    [userAgentString appendFormat:@"; %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]];
    [userAgentString appendFormat:@"; STR %@", [STRVersion current]];
    
    return  userAgentString;
}

@end
