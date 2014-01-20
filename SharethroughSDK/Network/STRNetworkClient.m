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

    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            [deferred rejectWithError:connectionError];
        } else {
            [deferred resolveWithValue:data];
        }
    }];

    return deferred.promise;
}

@end
