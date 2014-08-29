//
//  STRDFPManager.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/27/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRDFPManager.h"

#import "STRAdGenerator.h"
#import "STRAppModule.h"
#import "STRInjector.h"
#import "STRDeferred.h"

@interface STRDFPManager ()

@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) NSMutableDictionary *adPlacementCache;

@end

@implementation STRDFPManager

+ (id)sharedInstance {
    __strong static STRDFPManager *sharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
        sharedObject.injector = [STRInjector injectorForModule:[STRAppModule new]];;
        sharedObject.adPlacementCache = [NSMutableDictionary dictionary];
    });

    return sharedObject;
}

- (void)cacheAdPlacement:(STRAdPlacement *)adPlacement {
    [self.adPlacementCache setObject:adPlacement forKey:adPlacement.placementKey];
}

- (STRPromise *)renderCreative:(NSString *)creativeKey inPlacement:(NSString *)placementKey {
    STRDeferred *deferred = [STRDeferred defer];

    STRAdPlacement *adPlacement = [self.adPlacementCache objectForKey:placementKey];

    STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
    [generator placeAdInView:adPlacement.adView
                placementKey:adPlacement.placementKey
    presentingViewController:adPlacement.presentingViewController
                    delegate:adPlacement.delegate];

    [deferred resolveWithValue:adPlacement.adView];

    return deferred.promise;
}

@end
