//
//  STRAdService.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRAdCache.h"
#import "STRAdYouTube.h"
#import "STRAdVine.h"

@interface STRAdService ()

@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, strong) STRAdCache *adCache;

@end

@implementation STRAdService

- (id)initWithRestClient:(STRRestClient *)restClient networkClient:(STRNetworkClient *)networkClient adCache:(STRAdCache *)adCache {
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.networkClient = networkClient;
        self.adCache = adCache;
    }

    return self;
}

- (STRPromise *)fetchAdForPlacementKey:(NSString *)placementKey {
    STRDeferred *deferred = [STRDeferred defer];

    STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacementKey:placementKey];
    if (cachedAd) {
        [deferred resolveWithValue:cachedAd];
        return deferred.promise;
    }

    STRPromise *adPromise = [self.restClient getWithParameters: @{@"placement_key": placementKey}];
    [adPromise then:^id(NSDictionary *fullJSON) {
        NSDictionary *adJSON = fullJSON[@"creative"];

        NSURL *sanitizedThumbnailURL = [NSURL URLWithString:adJSON[@"thumbnail_url"]];
        if (![sanitizedThumbnailURL scheme]) {
            sanitizedThumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@", adJSON[@"thumbnail_url"]]];
        }

        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:sanitizedThumbnailURL];

        [[self.networkClient get:imageRequest] then:^id(NSData *data) {
            STRAdvertisement *ad = [self adForAction:adJSON[@"action"]];
            ad.advertiser = adJSON[@"advertiser"];
            ad.title = adJSON[@"title"];
            ad.adDescription = adJSON[@"description"];
            ad.creativeKey = adJSON[@"creative_key"];
            ad.variantKey = adJSON[@"variant_key"];
            ad.mediaURL = [NSURL URLWithString:adJSON[@"media_url"]];
            ad.shareURL = [NSURL URLWithString:adJSON[@"share_url"]];
            ad.thumbnailImage = [UIImage imageWithData:data];
            ad.placementKey = placementKey;
            ad.thirdPartyBeaconsForVisibility = adJSON[@"beacons"][@"visible"];
            ad.thirdPartyBeaconsForClick = adJSON[@"beacons"][@"click"];
            ad.thirdPartyBeaconsForPlay = adJSON[@"beacons"][@"play"];

            [self.adCache saveAd:ad];
            [deferred resolveWithValue:ad];
            return data;
        } error:^id(NSError *error) {
            [deferred rejectWithError:error];
            return error;
        }];

        return adJSON;
    } error:^id(NSError *error) {
        [deferred rejectWithError:error];
        return error;
    }];
    
    return deferred.promise;
}

#pragma mark - Private

- (STRAdvertisement *)adForAction:(NSString *)action {
    NSDictionary *actionsToClasses = @{@"video": [STRAdYouTube class], @"vine": [STRAdVine class]};
    Class adClass = actionsToClasses[action];
    if (!adClass) {
        adClass = [STRAdvertisement class];
    }
    return [adClass new];
}

@end
