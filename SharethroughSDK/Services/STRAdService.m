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
#import "STRAdClickout.h"
#import "STRAdPinterest.h"
#import "STRBeaconService.h"

@interface STRAdService ()

@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, strong) STRAdCache *adCache;
@property (nonatomic, strong) STRBeaconService *beaconService;

@end

@implementation STRAdService

- (id)initWithRestClient:(STRRestClient *)restClient
           networkClient:(STRNetworkClient *)networkClient
                 adCache:(STRAdCache *)adCache
           beaconService:(STRBeaconService *)beaconService
{
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.networkClient = networkClient;
        self.adCache = adCache;
        self.beaconService = beaconService;
    }

    return self;
}

- (STRPromise *)fetchAdForPlacementKey:(NSString *)placementKey {
    STRDeferred *deferred = [STRDeferred defer];

    if (![self.adCache isAdStale:placementKey]) {
        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacementKey:placementKey];
        [deferred resolveWithValue:cachedAd];
        return deferred.promise;
    }

    [self.beaconService fireImpressionRequestForPlacementKey:placementKey];
    STRPromise *adPromise = [self.restClient getWithParameters: @{@"placement_key": placementKey}];
    [adPromise then:^id(NSDictionary *fullJSON) {
        NSDictionary *creativeJSON = fullJSON[@"creative"];

        NSURL *sanitizedThumbnailURL = [NSURL URLWithString:creativeJSON[@"thumbnail_url"]];
        if (![sanitizedThumbnailURL scheme]) {
            sanitizedThumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@", creativeJSON[@"thumbnail_url"]]];
        }

        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:sanitizedThumbnailURL];

        [[self.networkClient get:imageRequest] then:^id(NSData *data) {
            STRAdvertisement *ad = [self adForAction:creativeJSON[@"action"]];
            ad.advertiser = creativeJSON[@"advertiser"];
            ad.title = creativeJSON[@"title"];
            ad.adDescription = creativeJSON[@"description"];
            ad.creativeKey = creativeJSON[@"creative_key"];
            ad.variantKey = creativeJSON[@"variant_key"];
            ad.mediaURL = [NSURL URLWithString:creativeJSON[@"media_url"]];
            ad.shareURL = [NSURL URLWithString:creativeJSON[@"share_url"]];
            ad.thumbnailImage = [UIImage imageWithData:data];
            ad.placementKey = placementKey;
            ad.thirdPartyBeaconsForVisibility = creativeJSON[@"beacons"][@"visible"];
            ad.thirdPartyBeaconsForClick = creativeJSON[@"beacons"][@"click"];
            ad.thirdPartyBeaconsForPlay = creativeJSON[@"beacons"][@"play"];
            ad.signature = fullJSON[@"signature"];
            ad.auctionPrice = fullJSON[@"price"];
            ad.auctionType = fullJSON[@"priceType"];
            ad.action = creativeJSON[@"action"];

            [self.adCache saveAd:ad];
            [deferred resolveWithValue:ad];
            return data;
        } error:^id(NSError *error) {
            [deferred rejectWithError:error];
            return error;
        }];

        return creativeJSON;
    } error:^id(NSError *error) {
        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacementKey:placementKey];
        
        if (cachedAd != nil) {
            [deferred resolveWithValue:cachedAd];
        } else {
            [deferred rejectWithError:error];
        }
        return error;
    }];
    
    return deferred.promise;
}

#pragma mark - Private

- (STRAdvertisement *)adForAction:(NSString *)action {
    NSDictionary *actionsToClasses = @{@"video": [STRAdYouTube class], @"vine": [STRAdVine class], @"clickout": [STRAdClickout class], @"pinterest": [STRAdPinterest class], @"instagram": [STRAdClickout class]};
    Class adClass = actionsToClasses[action];
    if (!adClass) {
        adClass = [STRAdvertisement class];
    }
    return [adClass new];
}

@end
