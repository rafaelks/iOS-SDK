//
//  SharethroughSDK.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "SharethroughSDK.h"
#import "STRAdGenerator.h"
#import "STRRestClient.h"

@interface SharethroughSDK ()

@property (nonatomic, assign, readwrite, getter=isStaging) BOOL staging;
@property (nonatomic, assign, readwrite) NSString *priceKey;
@property (nonatomic, strong) STRRestClient *restClient;

@end

@implementation SharethroughSDK

+ (instancetype)sharedInstance {

    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
    });

    return sharedObject;
}

- (void)configureWithPriceKey:(NSString *)priceKey isStaging:(BOOL)staging {
    self.staging = staging;
    self.priceKey = priceKey;
    self.restClient = [[STRRestClient alloc] initWithStaging:self.isStaging];
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey {
    STRAdGenerator *generator = [[STRAdGenerator alloc] initWithPriceKey:self.priceKey restClient:self.restClient];
    [generator placeAdInView:view placementKey:placementKey];
}


@end
