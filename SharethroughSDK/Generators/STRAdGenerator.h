//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRAdView, STRAdViewDelegate;
@class STRAdPlacement, STRBeaconService, STRInjector, STRPromise, STRAsapService;

@interface STRAdGenerator : NSObject

- (id)initWithAsapService:(STRAsapService *)asapService injector:(STRInjector *)injector;

- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement;

- (STRPromise *)prefetchAdForPlacement:(STRAdPlacement *)placement;
@end
