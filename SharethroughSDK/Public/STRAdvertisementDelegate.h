//
//  STRAdvertisementDelegate.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 6/5/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRAdvertisement;

@protocol STRAdvertisementDelegate <NSObject>

@optional

- (void)adWillLogImpression:(STRAdvertisement *)StrAd;

- (void)adDidClick:(STRAdvertisement *)StrAd;

@end