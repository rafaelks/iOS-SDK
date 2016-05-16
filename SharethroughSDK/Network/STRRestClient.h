//
//  STRRestClient.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRPromise.h"

@class STRNetworkClient;

@interface STRRestClient : NSObject

- (id)initWithNetworkClient:(STRNetworkClient *)networkClient;
- (STRPromise *)getAsapInfoWithParameters:(NSDictionary *)parameters;
- (STRPromise *)getWithParameters:(NSDictionary *)parameters;
- (STRPromise *)getDFPPathForPlacement:(NSString *)placementKey;
- (void)sendBeaconWithParameters:(NSDictionary *)parameters;
- (void)sendBeaconWithURL:(NSURL *)url;

- (NSString *)getUserAgent;
@end
