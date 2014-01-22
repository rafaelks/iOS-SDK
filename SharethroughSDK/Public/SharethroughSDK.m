//
//  SharethroughSDK.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/17/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "SharethroughSDK.h"
#import "STRAdGenerator.h"
#import "STRAdService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"

@interface SharethroughSDK ()

@property (nonatomic, assign, readwrite, getter=isStaging) BOOL staging;
@property (nonatomic, copy, readwrite) NSString *priceKey;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRAdGenerator *generator;

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
    self.networkClient = [STRNetworkClient new];
    self.restClient = [[STRRestClient alloc] initWithStaging:self.isStaging networkClient:self.networkClient];
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey presentingViewController:(UIViewController *)presentingViewController {
    STRAdService *adService = [[STRAdService alloc] initWithRestClient:self.restClient networkClient:self.networkClient];
    self.generator = [[STRAdGenerator alloc] initWithPriceKey:self.priceKey adService:adService];
    [self.generator placeAdInView:view placementKey:placementKey presentingViewController:presentingViewController];
}


@end
