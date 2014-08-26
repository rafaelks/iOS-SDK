//
//  STRDFPAdGenerator.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/26/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <objc/runtime.h>

#import "STRDFPAdGenerator.h"

#import "STRAdView.h"
#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#import "STRBeaconService.h"
#import "STRAdViewDelegate.h"

char const * const STRDFPAdGeneratorKey = "STRDFPAdGeneratorKey";

@interface STRDFPAdGenerator ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, strong) STRAdvertisement *ad;
@property (nonatomic, weak) STRInjector *injector;
@property (strong, non)

@end

@implementation STRDFPAdGenerator

- (id)initWithAdService:(STRAdService *)adService
          beaconService:(STRBeaconService *)beaconService
                runLoop:(NSRunLoop *)timerRunLoop
               injector:(STRInjector *)injector {
    self = [super init];
    if (self) {
        self.adService = adService;
        self.injector = injector;
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {
    
}

@end
