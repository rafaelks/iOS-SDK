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

static NSString *const stxMonetize = @"STX_MONETIZE";
static NSString *const dfpCreativeKey = @"creative_key";
static NSString *const dfpCampaignKey = @"campaign_key";


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
    [self.adPlacementCache setObject:adPlacement forKey:adPlacement.DFPPath];
}

- (STRPromise *)renderAdForParameter:(NSString *)parameter inPlacement:(NSString *)DFPPath {
    STRDeferred *deferred = [STRDeferred defer];

    STRAdPlacement *adPlacement = [self.adPlacementCache objectForKey:DFPPath];

    if (parameter == nil || [parameter length] == 0 || adPlacement.placementKey == nil || [adPlacement.placementKey length] == 0) {
        NSLog(@"Invalid parameter %@ or placementKey %@. Not reaching out to Sharethrough for Ad.", parameter, adPlacement.placementKey);
        NSError *error = [NSError errorWithDomain:@"Sharethrough invalid params" code:-1 userInfo:nil];
        [deferred rejectWithError:error];
    } else {
        STRAdGenerator *generator = [self.injector getInstance:[STRAdGenerator class]];
        STRPromise *promise;

        if ([parameter isEqualToString:stxMonetize]) {
            if (adPlacement.DFPDeferred != nil) {
                promise = [generator prefetchAdForPlacement:adPlacement];
            } else {
                promise = [generator placeAdInPlacement:adPlacement];
            }
        } else if ([parameter rangeOfString:dfpCreativeKey options:NSCaseInsensitiveSearch].location != NSNotFound ||
                   [parameter rangeOfString:dfpCampaignKey options:NSCaseInsensitiveSearch].location != NSNotFound)
        {
            NSArray *parameterParts = [parameter componentsSeparatedByString:@"="];
            if (parameterParts.count != 2) {
                NSLog(@"Invalid parameter %@, is not correctly formatted with %@=<key> or %@=<key>", parameter, dfpCampaignKey, dfpCreativeKey);
                NSError *error = [NSError errorWithDomain:@"Sharethrough invalid params" code:-1 userInfo:nil];
                [deferred rejectWithError:error];
            } else {
                if (adPlacement.DFPDeferred != nil) {
                    promise = [generator prefetchForPlacement:adPlacement auctionParameterKey:parameterParts[0] auctionParameterValue:parameterParts[1]];
                } else {
                    promise = [generator placeAdInPlacement:adPlacement auctionParameterKey:parameterParts[0] auctionParameterValue:parameterParts[1]];
                }
            }
        } else { //fall back support for older params
            if (adPlacement.DFPDeferred != nil) {
                promise = [generator prefetchForPlacement:adPlacement auctionParameterKey:dfpCreativeKey auctionParameterValue:parameter];
            } else {
                promise = [generator placeAdInPlacement:adPlacement auctionParameterKey:dfpCreativeKey auctionParameterValue:parameter];
            }
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
    }

    return deferred.promise;
}

- (void)updateDelegateWithNoAdShownforPlacement:(NSString *)DFPPath {
    STRAdPlacement *adPlacement = [self.adPlacementCache objectForKey:DFPPath];

    if ([adPlacement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:atIndex:)]) {
        [adPlacement.delegate adView:adPlacement.adView didFailToFetchAdForPlacementKey:adPlacement.placementKey atIndex:0];
    }
}

@end
