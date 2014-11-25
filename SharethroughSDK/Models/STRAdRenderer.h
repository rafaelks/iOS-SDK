//
//  STRAdRenderer.h
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/29/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdvertisement, STRAdPlacement, STRBeaconService, STRNetworkClient, STRInjector;

@interface STRAdRenderer : NSObject

- (id)initWithBeaconService:(STRBeaconService *)beaconService
                    runLoop:(NSRunLoop *)timerRunLoop
              networkClient:(STRNetworkClient *)networkClient
                   injector:(STRInjector *)injector;

- (void)renderAd:(STRAdvertisement *)ad inPlacement:(STRAdPlacement *)placement;
@end
