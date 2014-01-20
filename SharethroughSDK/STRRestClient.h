//
//  STRRestClient.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRPromise;

@interface STRRestClient : NSObject

- (id)initWithStaging:(BOOL)isStaging;
- (STRPromise *)getWithParameters:(NSDictionary *)parameters;

@end
