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
#import "STRDeferred.h"

@interface STRDFPManager ()

@property (nonatomic, strong) NSMutableDictionary *adPlacementCache;

@end

@implementation STRDFPManager

+ (id)sharedInstance {
    __strong static STRDFPManager *sharedObject = nil;

    static dispatch_once_t p = 0;
    dispatch_once(&p, ^{
        sharedObject = [[self alloc] init];
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
    STRPromise *promise;

    if (adPlacement.DFPDeferred != nil) {
        promise = [generator prefetchCreative:creativeKey forPlacement:adPlacement];
    } else {
        promise = [generator placeCreative:creativeKey inPlacement:adPlacement];
    }

    [promise then:^id(id value) {
        if (adPlacement.DFPDeferred != nil) {
            [adPlacement.DFPDeferred resolveWithValue:nil];
        }
        [deferred resolveWithValue:adPlacement.adView];
        return value;
    } error:^id(NSError *error) {
        if (adPlacement.DFPDeferred != nil) {
            [adPlacement.DFPDeferred rejectWithError:error];
        }
        [deferred rejectWithError:error];
        return error;
    }];

    return deferred.promise;
}

@end