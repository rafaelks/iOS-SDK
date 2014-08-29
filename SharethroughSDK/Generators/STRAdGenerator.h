//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRPromise.h"

@protocol STRAdView, STRAdViewDelegate;
@class STRAdPlacement, STRAdService, STRBeaconService, STRInjector;

extern char const * const STRAdGeneratorKey;

@interface STRAdGenerator : NSObject

- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService runLoop:(NSRunLoop *)timerRunLoop injector:(STRInjector *)injector;

- (void)placeAdInPlacement:(STRAdPlacement *)placement;

- (STRPromise *)prefetchAdForPlacementKey:(NSString *)placementKey;
@end
