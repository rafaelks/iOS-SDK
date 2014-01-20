//
//  STRAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STRAdView;
@class STRRestClient;

@interface STRAdGenerator : NSObject

- (id)initWithPriceKey:(NSString *)priceKey restClient:(STRRestClient *)restClient;
- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey;

@end
