//
//  STRNetworkClient.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRPromise.h"

@interface STRNetworkClient : NSObject

- (STRPromise *)get:(NSURLRequest *)request;

@end
