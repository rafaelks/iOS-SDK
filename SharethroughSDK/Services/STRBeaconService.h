//
//  STRBeaconService.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRRestClient, STRNetworkClient, STRDateProvider;

@interface STRBeaconService : NSObject

- (id) initWithRestClient:(STRRestClient *)restClient dateProvider:(STRDateProvider *)dateProvider;;
- (void)fireImpressionRequestForPlacementKey:(NSString *)placementKey;

@end
