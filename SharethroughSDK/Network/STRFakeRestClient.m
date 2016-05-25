//
//  STRFakeRestClient.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 9/28/15.
//  Copyright © 2015 Sharethrough. All rights reserved.
//

#import "STRFakeRestClient.h"
#import "STRDeferred.h"

@implementation STRFakeRestClient

- (STRPromise *)getWithParameters:(NSDictionary *)parameters {
    STRDeferred *deferred = [STRDeferred defer];
    [deferred rejectWithError:nil];
    return deferred.promise;
}

- (void)sendBeaconWithParameters:(NSDictionary *)parameters {
    //Do nothing
}

- (void)sendBeaconWithURL:(NSURL *)url{
    //Do nothing
}

@end
