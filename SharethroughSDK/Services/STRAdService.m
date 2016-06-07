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
#import "STRAdArticle.h"
#import "STRAdCache.h"
#import "STRAdYouTube.h"
#import "STRAdVine.h"
#import "STRAdClickout.h"
#import "STRAdPinterest.h"
#import "STRAdInstagram.h"
#import "STRBeaconService.h"
#import "STRAdPlacement.h"
#import "STRAdHostedVideo.h"
#import "STRAdInstantHostedVideo.h"
#import <AdSupport/AdSupport.h>
#import "STRLogging.h"

const NSInteger kRequestInProgress = 202;

@interface STRAdService ()

@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, strong) STRAdCache *adCache;
@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, weak) ASIdentifierManager *identifierManager;
@property (nonatomic, weak) STRInjector *injector;

@end

@implementation STRAdService

- (id)initWithRestClient:(STRRestClient *)restClient
           networkClient:(STRNetworkClient *)networkClient
                 adCache:(STRAdCache *)adCache
           beaconService:(STRBeaconService *)beaconService
     asIdentifierManager:(ASIdentifierManager *)identifierManager
                injector:(STRInjector *)injector
{
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.networkClient = networkClient;
        self.adCache = adCache;
        self.beaconService = beaconService;
        self.identifierManager = identifierManager;
        self.injector = injector;
    }

    return self;
}

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)prefetch{
    TLog(@"");
    [self.beaconService fireImpressionRequestForPlacement:placement];
    return [self fetchAdWithParameters:[self createAdRequestParamsForPlacement:placement withOtherParams:@{}]
                          forPlacement:placement
                            isPrefetch:prefetch];
}

- (STRPromise *)fetchAdForPlacement:(STRAdPlacement *)placement
                auctionParameterKey:(NSString *)apKey
              auctionParameterValue:(NSString *)apValue
                         isPrefetch:(BOOL)prefetch
{
    TLog(@"pkey: %@, apkey: %@, apval: %@, prefetch: %@", placement.placementKey, apKey, apValue, prefetch ? @"YES" : @"NO");
    [self.beaconService fireImpressionRequestForPlacement:placement auctionParameterKey:apKey auctionParameterValue:apValue];
    return [self fetchAdWithParameters:[self createAdRequestParamsForPlacement:placement withOtherParams:@{ apKey : apValue }]
                          forPlacement:placement
                  isPrefetch:prefetch];
}

- (BOOL)isAdCachedForPlacement:(STRAdPlacement *)placement {
    TLog(@"");
    return [self.adCache isAdAvailableForPlacement:placement AndInitializeAd:NO];
}

#pragma mark - Private

- (STRPromise *)fetchAdWithParameters:(NSDictionary *)parameters forPlacement:(STRAdPlacement *)placement isPrefetch:(BOOL)prefetch {
    TLog(@"");
    STRDeferred *deferred = [STRDeferred defer];

    STRPromise *adPromise = [self.restClient getWithParameters: parameters];
    [adPromise then:^id(NSDictionary *fullJSON) {
        NSArray *creativesJSON = fullJSON[@"creatives"];
        NSDictionary *placementJSON = fullJSON[@"placement"];
        NSString *adserverRequestId = fullJSON[@"adserverRequestId"];

        if ([creativesJSON count] == 0) {
            TLog(@"No creatives received");
            NSError *noCreativesError = [NSError errorWithDomain:@"No creatives returned" code:404 userInfo:nil];
            [deferred rejectWithError:noCreativesError];
            return noCreativesError;
        }

        NSMutableArray *creativesArray = [NSMutableArray arrayWithCapacity:[creativesJSON count]];

        for (int i = 0; i < [creativesJSON count]; ++i) {
            [creativesArray addObject: [self createAdvertisementFromJSON:creativesJSON[i] forPlacement:placement withPlacementJSON:placementJSON withArid:adserverRequestId]];
        }

        [self createPlacementInfiniteScrollExtrasFromJSON:fullJSON[@"placement"] forPlacement:placement];
        STRPromise *creativeImagesPromise = [STRPromise when:creativesArray];
        [creativeImagesPromise then:^id(NSMutableArray *creatives) {
            [self.adCache saveAds:creatives forPlacement:placement andAssignAds:!prefetch];

            if (!prefetch) {
                [deferred resolveWithValue:[self.adCache fetchCachedAdForPlacement:placement]];
            } else {
                [deferred resolveWithValue:creatives[0]];
            }

            return nil;
        } error:^id(NSError *error) {
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

- (NSURL *)URLFromSanitizedString:(NSString*)urlString {
    NSURL *sanitizedURL = [NSURL URLWithString:urlString];
    if (sanitizedURL != nil && ![sanitizedURL scheme]) {
        sanitizedURL = [NSURL URLWithString:[NSString stringWithFormat:@"https:%@", urlString]];
    }
    return sanitizedURL;
}

- (STRAdvertisement *)adForCreative:(NSDictionary *)creativeJSON inPlacement:(NSDictionary *)placementJSON {
    NSString *action = creativeJSON[@"action"];
    TLog(@"action:%@",action);
    NSDictionary *actionsToClasses = @{@"video": [STRAdYouTube class],
                                       @"hosted-video": [STRAdHostedVideo class],
                                       @"vine": [STRAdVine class],
                                       @"clickout": [STRAdClickout class],
                                       @"article": [STRAdArticle class],
                                       @"pinterest": [STRAdPinterest class],
                                       @"instagram": [STRAdInstagram class]
                                       };
    Class adClass = actionsToClasses[action];
    if ([action isEqualToString:@"hosted-video"]) {
        BOOL force_click_to_play = [creativeJSON[@"force_click_to_play"] boolValue];
        BOOL allowInstantPlay = [placementJSON[@"allowInstantPlay"] boolValue];
        TLog(@"Force Click To Play: %@, Allow Instant Play: %@", force_click_to_play ? @"YES" : @"NO", allowInstantPlay ? @"YES" : @"NO");
        if (!force_click_to_play && allowInstantPlay) {
            adClass = [STRAdInstantHostedVideo class];
        }
    }
    if (!adClass) {
        adClass = [STRAdvertisement class];
    }
    return [[adClass alloc] initWithInjector:self.injector];
}

- (STRPromise *)createAdvertisementFromJSON:(NSDictionary *)creativeWrapperJSON forPlacement:(STRAdPlacement *)placement withPlacementJSON:(NSDictionary *)placementJSON withArid:(NSString *)adserverRequestId {
    TLog(@"");
    STRDeferred *deferred = [STRDeferred defer];

    NSDictionary *creativeJSON = creativeWrapperJSON[@"creative"];

    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[self URLFromSanitizedString:creativeJSON[@"thumbnail_url"]]];
    [[self.networkClient get:imageRequest] then:^id(NSData *data) {
        STRAdvertisement *ad = [self adForCreative:creativeJSON inPlacement:placementJSON];
        ad.thumbnailImage = [UIImage imageWithData:data];
        ad.advertiser = creativeJSON[@"advertiser"];
        ad.title = creativeJSON[@"title"];
        ad.adDescription = creativeJSON[@"description"];
        ad.creativeKey = creativeJSON[@"creative_key"];
        ad.variantKey = creativeJSON[@"variant_key"];
        ad.mediaURL = [self URLFromSanitizedString:creativeJSON[@"media_url"]];
        ad.shareURL = [self URLFromSanitizedString:creativeJSON[@"share_url"]];
        ad.brandLogoURL = [self URLFromSanitizedString:creativeJSON[@"brand_logo_url"]];
        ad.placementKey = placement.placementKey;
        ad.placementStatus = placementJSON[@"status"];
        ad.promotedByText = placementJSON[@"promoted_by_text"];
        ad.thirdPartyBeaconsForImpression = creativeJSON[@"beacons"][@"impression"];
        ad.thirdPartyBeaconsForVisibility = creativeJSON[@"beacons"][@"visible"];
        ad.thirdPartyBeaconsForClick = creativeJSON[@"beacons"][@"click"];
        ad.thirdPartyBeaconsForPlay = creativeJSON[@"beacons"][@"play"];
        ad.thirdPartyBeaconsForSilentPlay = creativeJSON[@"beacons"][@"silent_play"];
        ad.thirdPartyBeaconsForTenSecondSilentPlay = creativeJSON[@"beacons"][@"ten_second_silent_play"];
        ad.action = creativeJSON[@"action"];
        ad.adserverRequestId = adserverRequestId;
        ad.auctionWinId = creativeWrapperJSON[@"auctionWinId"];
        ad.mrid = placement.mrid;
        ad.brandLogoURL = [self URLFromSanitizedString:creativeJSON[@"brand_logo_url"]];
        ad.thumbnailURL = [self URLFromSanitizedString:creativeJSON[@"thumbnail_url"]];
        ad.customEngagementLabel = creativeJSON[@"custom_engagement_label"];
        ad.customEngagementURL = [self URLFromSanitizedString:creativeJSON[@"custom_engagement_url"]];
        ad.dealId = creativeWrapperJSON[@"deal_id"];
        ad.optOutUrlString = creativeJSON[@"opt_out_url"];
        ad.optOutText = creativeJSON[@"opt_out_text"];
        ad.injector = self.injector;

        [deferred resolveWithValue:ad];

        return ad;
    } error:^id(NSError *error) {
        [deferred rejectWithError:error];
        return error;
    }];
    return deferred.promise;
}

- (void)createPlacementInfiniteScrollExtrasFromJSON:(NSDictionary *)placementJSON
                                    forPlacement:(STRAdPlacement *)placement {
    TLog(@"");
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
    TLog(@"adRequestParams:%@",returnValue);
    return returnValue;
}

@end
