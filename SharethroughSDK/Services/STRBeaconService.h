//
//  STRBeaconService.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRRestClient, STRNetworkClient, STRDateProvider, ASIdentifierManager, STRAdvertisement;

@interface STRBeaconService : NSObject

- (id) initWithRestClient:(STRRestClient *)restClient dateProvider:(STRDateProvider *)dateProvider asIdentifierManager:(ASIdentifierManager *)identifierManager;
- (void)fireImpressionRequestForPlacementKey:(NSString *)placementKey;
- (void)fireImpressionForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize;
- (void)fireThirdPartyBeacons:(NSArray *)beaconPaths;
- (void)fireVisibleImpressionForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize;
- (void)fireVideoPlayEvent:(STRAdvertisement *)ad adSize:(CGSize)size;
- (void)fireShareForAd:(STRAdvertisement *)ad shareType:(NSString *)uiActivityType;

@end
