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
#import "STRAdInstagram.h"
#import "STRBeaconService.h"
#import "STRAdPlacement.h"

const NSInteger kRequestInProgress = 202;

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

    if ([self.adCache isAdAvailableForPlacement:placementKey]) {
        STRDeferred *deferred = [STRDeferred defer];
        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacementKey:placementKey];
        [deferred resolveWithValue:cachedAd];
        if ([self.adCache shouldBeginFetchForPlacement:placementKey]) {
            [self beginFetchForPlacementKey:placementKey];
        }
        return deferred.promise;
    }

    if ([self.adCache pendingAdRequestInProgressForPlacement:placementKey]) {
        return [self requestInProgressError];
    }

    return [self beginFetchForPlacementKey:placementKey];
}

- (STRPromise *)fetchAdForPlacementKey:(NSString *)placementKey creativeKey:(NSString *)creativeKey {

    STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacementKey:placementKey CreativeKey:creativeKey];
    if (cachedAd) {
        STRDeferred *deferred = [STRDeferred defer];
        [deferred resolveWithValue:cachedAd];
        return deferred.promise;
    }

    if ([self.adCache pendingAdRequestInProgressForPlacement:placementKey]) {
        return [self requestInProgressError];
    }

    [self.beaconService fireImpressionRequestForPlacementKey:placementKey CreativeKey:creativeKey];
    return [self fetchAdWithParameters:@{@"placement_key": placementKey, @"creative_key": creativeKey} forPlacementKey:placementKey];
}

- (BOOL)isAdCachedForPlacementKey:(NSString *)placementKey {
    return [self.adCache isAdAvailableForPlacement:placementKey];
}

#pragma mark - Private

- (STRPromise *)beginFetchForPlacementKey:(NSString *)placementKey {
    [self.beaconService fireImpressionRequestForPlacementKey:placementKey];
    return [self fetchAdWithParameters:@{@"placement_key": placementKey} forPlacementKey:placementKey];
}

- (STRPromise *)fetchAdWithParameters:(NSDictionary *)parameters forPlacementKey:(NSString *)placementKey{
    STRDeferred *deferred = [STRDeferred defer];

    STRPromise *adPromise = [self.restClient getWithParameters: parameters];
    [adPromise then:^id(NSDictionary *fullJSON) {
        NSArray *creativesJSON = fullJSON[@"creatives"];

        NSMutableArray *creativesArray = [NSMutableArray arrayWithCapacity:[creativesJSON count]];

        for (int i = 0; i < [creativesJSON count]; i++) {
            [creativesArray addObject: [self createAdvertisementFromJSON:creativesJSON[i] forPlacement:placementKey]];
        }

        [self createPlacementInfiniteScrollExtrasFromJSON:fullJSON[@"placement"] forPlacementKey:placementKey];
        [self.adCache saveAds:creativesArray forPlacementKey:placementKey];

        [deferred resolveWithValue:creativesArray[0]];

        return nil;
    } error:^id(NSError *error) {
        [self.adCache clearPendingAdRequestForPlacement:placementKey];

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

- (STRPromise *)requestInProgressError {
    STRDeferred *deferred = [STRDeferred defer];
    [deferred rejectWithError:[NSError errorWithDomain:@"STR Request in Progress" code:kRequestInProgress userInfo:nil]];
    return deferred.promise;
}

- (NSURL *)URLFromSanitizedString:(NSString*)urlString {
    NSURL *sanitizedURL = [NSURL URLWithString:urlString];
    if (sanitizedURL != nil && ![sanitizedURL scheme]) {
        sanitizedURL = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@", urlString]];
    }
    return sanitizedURL;
}

- (STRAdvertisement *)adForAction:(NSString *)action {
    NSDictionary *actionsToClasses = @{@"video": [STRAdYouTube class],
                                       @"vine": [STRAdVine class],
                                       @"clickout": [STRAdClickout class],
                                       @"pinterest": [STRAdPinterest class],
                                       @"instagram": [STRAdInstagram class]
                                       };
    Class adClass = actionsToClasses[action];
    if (!adClass) {
        adClass = [STRAdvertisement class];
    }
    return [adClass new];
}

- (STRAdvertisement *)createAdvertisementFromJSON:(NSDictionary *)creativeWrapperJSON forPlacement:(NSString *)placementKey {
    NSDictionary *creativeJSON = creativeWrapperJSON[@"creative"];

    STRAdvertisement *ad = [self adForAction:creativeJSON[@"action"]];
    ad.advertiser = creativeJSON[@"advertiser"];
    ad.title = creativeJSON[@"title"];
    ad.adDescription = creativeJSON[@"description"];
    ad.creativeKey = creativeJSON[@"creative_key"];
    ad.variantKey = creativeJSON[@"variant_key"];
    ad.mediaURL = [NSURL URLWithString:creativeJSON[@"media_url"]];
    ad.shareURL = [NSURL URLWithString:creativeJSON[@"share_url"]];
    ad.brandLogoURL = [NSURL URLWithString:creativeJSON[@"brand_logo_url"]];
    ad.placementKey = placementKey;
    ad.thirdPartyBeaconsForVisibility = creativeJSON[@"beacons"][@"visible"];
    ad.thirdPartyBeaconsForClick = creativeJSON[@"beacons"][@"click"];
    ad.thirdPartyBeaconsForPlay = creativeJSON[@"beacons"][@"play"];
    ad.action = creativeJSON[@"action"];
    ad.signature = creativeWrapperJSON[@"signature"];
    ad.auctionPrice = creativeWrapperJSON[@"price"];
    ad.auctionType = creativeWrapperJSON[@"priceType"];
    ad.brandLogoURL = [self URLFromSanitizedString:creativeJSON[@"brand_logo_url"]];

    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self URLFromSanitizedString:creativeJSON[@"thumbnail_url"]]];
    [[self.networkClient get:imageRequest] then:^id(NSData *data) {
        ad.thumbnailImage = [UIImage imageWithData:data];
        return data;
    } error:^id(NSError *error) {
        return error;
    }];

    return ad;
}

- (void)createPlacementInfiniteScrollExtrasFromJSON:(NSDictionary *)placementJSON forPlacementKey:(NSString *)placementKey {
    if ([placementJSON[@"layout"] isEqualToString:@"multiple"] &&
        [self.adCache getInfiniteScrollFieldsForPlacement:placementKey] == nil) {
        
        STRAdPlacementInfiniteScrollFields *extras = [STRAdPlacementInfiniteScrollFields new];
        extras.placementKey = placementKey;
        extras.articlesBeforeFirstAd = [placementJSON[@"articlesBeforeFirstAd"] unsignedIntegerValue];
        extras.articlesBetweenAds = [placementJSON[@"articlesBetweenAds"] unsignedIntegerValue];
        extras.creativeArrayIndex = 0;
        [self.adCache saveInfiniteScrollFields:extras];
    }
}

@end
