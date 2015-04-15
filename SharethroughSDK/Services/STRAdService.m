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
#import <AdSupport/AdSupport.h>

const NSInteger kRequestInProgress = 202;

@interface STRAdService ()

@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, strong) STRAdCache *adCache;
@property (nonatomic, strong) STRBeaconService *beaconService;
@property (weak, nonatomic) ASIdentifierManager *identifierManager;

@end

@implementation STRAdService

- (id)initWithRestClient:(STRRestClient *)restClient
           networkClient:(STRNetworkClient *)networkClient
                 adCache:(STRAdCache *)adCache
           beaconService:(STRBeaconService *)beaconService
     asIdentifierManager:(ASIdentifierManager *)identifierManager
{
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.networkClient = networkClient;
        self.adCache = adCache;
        self.beaconService = beaconService;
        self.identifierManager = identifierManager;
    }

    return self;
}

- (STRPromise *)prefetchAdsForPlacement:(STRAdPlacement *)placement {
    if ([self.adCache pendingAdRequestInProgressForPlacement:placement.placementKey]) {
        return [self requestInProgressError];
    }

    return [self beginFetchForPlacement:placement andInitializeAtIndex:NO];
}

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement {
    if ([self.adCache isAdAvailableForPlacement:placement]) {
        STRDeferred *deferred = [STRDeferred defer];
        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacement:placement];
        [deferred resolveWithValue:cachedAd];
        if (!placement.isDirectSold && [self.adCache shouldBeginFetchForPlacement:placement.placementKey]) {
            [self beginFetchForPlacement:placement andInitializeAtIndex:NO];
        }
        return deferred.promise;
    }

    if ([self.adCache pendingAdRequestInProgressForPlacement:placement.placementKey]) {
        return [self requestInProgressError];
    }

    return [self beginFetchForPlacement:placement andInitializeAtIndex:YES];
}

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement creativeKey:(NSString *)creativeKey {

    STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacementKey:placement.placementKey CreativeKey:creativeKey];
    if (cachedAd) {
        STRDeferred *deferred = [STRDeferred defer];
        [deferred resolveWithValue:cachedAd];
        return deferred.promise;
    }

    if ([self.adCache pendingAdRequestInProgressForPlacement:placement.placementKey]) {
        return [self requestInProgressError];
    }

    [self.beaconService fireImpressionRequestForPlacementKey:placement.placementKey CreativeKey:creativeKey];
    return [self fetchAdWithParameters:[self createAdRequestParamsForPlacement:placement withOtherParams:@{ @"creative_key": creativeKey }]
                          forPlacement:placement
                  andInitializeAtIndex:YES];
}

- (BOOL)isAdCachedForPlacement:(STRAdPlacement *)placement {
    return [self.adCache isAdAvailableForPlacement:placement];
}

- (NSUInteger)numberOfAdsForPlacement:(STRAdPlacement *)placement {
    return [self.adCache numberOfAdsAvailableForPlacement:placement];
}

#pragma mark - Private

- (STRPromise *)beginFetchForPlacement:(STRAdPlacement *)placement andInitializeAtIndex:(BOOL)initializeAtIndex{
    [self.beaconService fireImpressionRequestForPlacementKey:placement.placementKey];
    return [self fetchAdWithParameters:[self createAdRequestParamsForPlacement:placement withOtherParams:@{}] forPlacement:placement andInitializeAtIndex:initializeAtIndex];
}

- (STRPromise *)fetchAdWithParameters:(NSDictionary *)parameters forPlacement:(STRAdPlacement *)placement andInitializeAtIndex:(BOOL)initializeAtIndex {
    STRDeferred *deferred = [STRDeferred defer];

    STRPromise *adPromise = [self.restClient getWithParameters: parameters];
    [adPromise then:^id(NSDictionary *fullJSON) {
        NSArray *creativesJSON = fullJSON[@"creatives"];
        NSDictionary *placementJSON = fullJSON[@"placement"];

        if ([creativesJSON count] == 0) {
            [self.adCache clearPendingAdRequestForPlacement:placement.placementKey];
            NSError *noCreativesError = [NSError errorWithDomain:@"No creatives returned" code:404 userInfo:nil];
            [deferred rejectWithError:noCreativesError];
            return noCreativesError;
        }

        NSMutableArray *creativesArray = [NSMutableArray arrayWithCapacity:[creativesJSON count]];

        for (int i = 0; i < [creativesJSON count]; ++i) {
            [creativesArray addObject: [self createAdvertisementFromJSON:creativesJSON[i] forPlacement:placement.placementKey withStatus:placementJSON[@"status"]]];
        }

        [self createPlacementInfiniteScrollExtrasFromJSON:fullJSON[@"placement"] forPlacement:placement];
        STRPromise *creativeImagesPromise = [STRPromise when:creativesArray];
        [creativeImagesPromise then:^id(NSMutableArray *creatives) {
            [self.adCache saveAds:creatives forPlacement:placement andInitializeAtIndex:initializeAtIndex];

            [deferred resolveWithValue:[self.adCache fetchCachedAdForPlacement:placement]];

            return nil;
        } error:^id(NSError *error) {
            [self.adCache clearPendingAdRequestForPlacement:placement.placementKey];

            STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacement:placement];
            if (cachedAd != nil) {
                [deferred resolveWithValue:cachedAd];
            } else {
                [deferred rejectWithError:error];
            }
            return error;
        }];

        return nil;
    } error:^id(NSError *error) {
        [self.adCache clearPendingAdRequestForPlacement:placement.placementKey];

        STRAdvertisement *cachedAd = [self.adCache fetchCachedAdForPlacement:placement];
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

- (STRPromise *)createAdvertisementFromJSON:(NSDictionary *)creativeWrapperJSON forPlacement:(NSString *)placementKey withStatus:(NSString *)placementStatus {
    STRDeferred *deferred = [STRDeferred defer];

    NSDictionary *creativeJSON = creativeWrapperJSON[@"creative"];

    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self URLFromSanitizedString:creativeJSON[@"thumbnail_url"]]];
    [[self.networkClient get:imageRequest] then:^id(NSData *data) {
        STRAdvertisement *ad = [self adForAction:creativeJSON[@"action"]];
        ad.thumbnailImage = [UIImage imageWithData:data];
        ad.advertiser = creativeJSON[@"advertiser"];
        ad.title = creativeJSON[@"title"];
        ad.adDescription = creativeJSON[@"description"];
        ad.creativeKey = creativeJSON[@"creative_key"];
        ad.variantKey = creativeJSON[@"variant_key"];
        ad.mediaURL = [NSURL URLWithString:creativeJSON[@"media_url"]];
        ad.shareURL = [NSURL URLWithString:creativeJSON[@"share_url"]];
        ad.brandLogoURL = [NSURL URLWithString:creativeJSON[@"brand_logo_url"]];
        ad.placementKey = placementKey;
        ad.placementStatus = placementStatus;
        ad.thirdPartyBeaconsForImpression = creativeJSON[@"beacons"][@"impression"];
        ad.thirdPartyBeaconsForVisibility = creativeJSON[@"beacons"][@"visible"];
        ad.thirdPartyBeaconsForClick = creativeJSON[@"beacons"][@"click"];
        ad.thirdPartyBeaconsForPlay = creativeJSON[@"beacons"][@"play"];
        ad.action = creativeJSON[@"action"];
        ad.signature = creativeWrapperJSON[@"signature"];
        ad.auctionPrice = creativeWrapperJSON[@"price"];
        ad.auctionType = creativeWrapperJSON[@"priceType"];
        ad.adserverRequestId = creativeWrapperJSON[@"adserverRequestId"];
        ad.auctionWinId = creativeWrapperJSON[@"auctionWinId"];
        ad.brandLogoURL = [self URLFromSanitizedString:creativeJSON[@"brand_logo_url"]];
        ad.customEngagementLabel = creativeJSON[@"custom_engagement_label"];
        ad.customEngagemnetURL = [self URLFromSanitizedString:creativeJSON[@"custom_engagement_url"]];

        [deferred resolveWithValue:ad];

        return ad;
    } error:^id(NSError *error) {
        return error;
    }];
    return deferred.promise;
}

- (void)createPlacementInfiniteScrollExtrasFromJSON:(NSDictionary *)placementJSON
                                    forPlacement:(STRAdPlacement *)placement {
    
    if ([placementJSON[@"layout"] isEqualToString:@"multiple"] &&
        [self.adCache getInfiniteScrollFieldsForPlacement:placement.placementKey] == nil) {

        STRAdPlacementInfiniteScrollFields *extras = [STRAdPlacementInfiniteScrollFields new];
        extras.placementKey = placement.placementKey;
        extras.articlesBeforeFirstAd = [placementJSON[@"articlesBeforeFirstAd"] unsignedIntegerValue];
        extras.articlesBetweenAds = [placementJSON[@"articlesBetweenAds"] unsignedIntegerValue];
        [self.adCache saveInfiniteScrollFields:extras];

        if ([placement.delegate respondsToSelector:@selector(adView:didFetchArticlesBeforeFirstAd:andArticlesBetweenAds:forPlacementKey:)]) {
            [placement.delegate adView:placement.adView didFetchArticlesBeforeFirstAd:extras.articlesBeforeFirstAd andArticlesBetweenAds:extras.articlesBetweenAds forPlacementKey:placement.placementKey];
        }
    }
}

- (NSDictionary *)createAdRequestParamsForPlacement:(STRAdPlacement *)placement withOtherParams:(NSDictionary *)otherParams {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName) {
        appName = @"";
    }
    NSString *bundleId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    if (!bundleId) {
        bundleId = @"";
    }
    NSString *idfa = @"";
    if ([self.identifierManager isAdvertisingTrackingEnabled]) {
        idfa = [[self.identifierManager advertisingIdentifier] UUIDString];
    }
    NSMutableDictionary *returnValue = [NSMutableDictionary dictionaryWithDictionary:otherParams];
    [returnValue addEntriesFromDictionary:@{@"placement_key": placement.placementKey, @"appName": appName, @"appId": bundleId, @"uid": idfa }];
    return returnValue;
}

@end
