//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRAdView, STRAdViewDelegate;
@class STRAdPlacement, STRAdService, STRBeaconService, STRInjector, STRPromise;

@interface STRAdGenerator : NSObject

- (id)initWithAdService:(STRAdService *)adService injector:(STRInjector *)injector;

- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement;
- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement auctionParameterKey:(NSString *)apKey auctionParameterValue:(NSString *)apValue;

- (STRPromise *)prefetchAdForPlacement:(STRAdPlacement *)placement;
- (STRPromise *)prefetchForPlacement:(STRAdPlacement *)placement auctionParameterKey:(NSString *)apKey auctionParameterValue:(NSString *)apValue;
@end
