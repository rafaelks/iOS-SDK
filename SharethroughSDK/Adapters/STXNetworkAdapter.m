//
//  STXNetworkAdapter.m
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/16/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <AdSupport/AdSupport.h>

#import "STRBeaconService.h"
#import "STRAdArticle.h"
#import "STRAdCache.h"
#import "STRAdClickout.h"
#import "STRAdInstagram.h"
#import "STRAdInstantHostedVideo.h"
#import "STRAdHostedVideo.h"
#import "STRAdPinterest.h"
#import "STRAdPlacement.h"
#import "STRAdvertisement.h"
#import "STRAdVine.h"
#import "STRAdYouTube.h"
#import "STRDeferred.h"
#import "STRInjector.h"
#import "STRLogging.h"
#import "STRNetworkClient.h"
#import "STRRestClient.h"
#import "STXNetworkAdapter.h"


@interface STXNetworkAdapter ()

@property (nonatomic, strong) STRBeaconService *beaconService;
@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRNetworkClient *networkClient;
@property (nonatomic, weak) ASIdentifierManager *identifierManager;

@end


@implementation STXNetworkAdapter

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}

-(void)loadAdWithParameters:(NSDictionary *)parameters {
    [self postInit];
    NSString *keyType = parameters[@"keyType"];
    NSString *keyValue = parameters[@"keyValue"];

    [self fireImpressionRequestBeaconForKey:keyType Value:keyValue];
    NSDictionary *adRequestParamsForPlacement = [self createAdRequestParamsForPlacement:self.placement
                                                                                withKey:keyType andValue:keyValue];
    [self fetchAdWithParameters:adRequestParamsForPlacement forPlacement:self.placement];
}

#pragma mark - Private

- (void)postInit {
    // TODO: validate injector
    self.beaconService = [self.injector getInstance:[STRBeaconService class]];
    self.restClient = [self.injector getInstance:[STRRestClient class]];
    self.identifierManager = [self.injector getInstance:[ASIdentifierManager class]];
    self.networkClient = [self.injector getInstance:[STRNetworkClient class]];
}

- (BOOL)isDirectSold:(NSString *)keyType {
    return [keyType isEqualToString:@"creative_key"] || [keyType isEqualToString:@"campaign_key"];
}

- (void)fireImpressionRequestBeaconForKey:(NSString *)key Value:(NSString *)value {
    if ([self isDirectSold:key]) {
        [self.beaconService fireImpressionRequestForPlacement:self.placement auctionParameterKey:key auctionParameterValue:value];
    } else {
        [self.beaconService fireImpressionRequestForPlacement:self.placement];
    }
}

- (NSDictionary *)additionalAdRequestParameters:(NSString *)key value:(NSString *)value {
    if ([self isDirectSold:key]) {
        return @{ key : value };
    } else {
        return @{};
    }
}

- (NSDictionary *)createAdRequestParamsForPlacement:(STRAdPlacement *)placement withKey:(NSString *)key andValue:(NSString *)value {
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
    NSDictionary *otherParams = [self additionalAdRequestParameters:key value:value];
    NSMutableDictionary *returnValue = [NSMutableDictionary dictionaryWithDictionary:otherParams];
    [returnValue addEntriesFromDictionary:@{@"placement_key": placement.placementKey, @"appName": appName, @"appId": bundleId, @"uid": idfa }];
    TLog(@"adRequestParams:%@",returnValue);
    return returnValue;
}

- (void)fetchAdWithParameters:(NSDictionary *)parameters forPlacement:(STRAdPlacement *)placement {
    TLog(@"");

    STRPromise *adPromise = [self.restClient getWithParameters: parameters];
    [adPromise then:^id(NSDictionary *fullJSON) {
        NSArray *creativesJSON = fullJSON[@"creatives"];
        NSDictionary *placementJSON = fullJSON[@"placement"];
        NSString *adserverRequestId = fullJSON[@"adserverRequestId"];

        if ([creativesJSON count] == 0) {
            TLog(@"No creatives received");
            NSError *noCreativesError = [NSError errorWithDomain:@"No creatives returned" code:404 userInfo:nil];
            [self.delegate strNetworkAdapter:self didFailToLoadAdWithError:noCreativesError];
            return noCreativesError;
        }

        NSMutableArray *creativesArray = [NSMutableArray arrayWithCapacity:[creativesJSON count]];

        for (int i = 0; i < [creativesJSON count]; ++i) {
            [creativesArray addObject: [self createAdvertisementFromJSON:creativesJSON[i] forPlacement:placement withPlacementJSON:placementJSON withArid:adserverRequestId]];
        }

        // TODO: Pull out "articlesBeforeFirstAd" and "articlesBetweenAds" in ASAP service
//        [self createPlacementInfiniteScrollExtrasFromJSON:fullJSON[@"placement"] forPlacement:placement];

        STRPromise *creativeImagesPromise = [STRPromise when:creativesArray];
        [creativeImagesPromise then:^id(NSMutableArray *creatives) {
            [self.delegate strNetworkAdapter:self didLoadMultipleAds:creatives];
            return nil;
        } error:^id(NSError *error) {
            [self.delegate strNetworkAdapter:self didFailToLoadAdWithError:[NSError errorWithDomain:@"Failed to load ads" code:404 userInfo:nil]];
            return error;
        }];

        return nil;
    } error:^id(NSError *error) {
        [self.delegate strNetworkAdapter:self didFailToLoadAdWithError:[NSError errorWithDomain:@"Failed to load ads" code:404 userInfo:nil]];
        return error;
    }];
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

// TODO: Move to ASAP service
//- (void)createPlacementInfiniteScrollExtrasFromJSON:(NSDictionary *)placementJSON
//                                       forPlacement:(STRAdPlacement *)placement {
//    TLog(@"");
//    if ([placementJSON[@"layout"] isEqualToString:@"multiple"] &&
//        [self.adCache getInfiniteScrollFieldsForPlacement:placement.placementKey] == nil) {
//
//        STRAdPlacementInfiniteScrollFields *extras = [STRAdPlacementInfiniteScrollFields new];
//        extras.placementKey = placement.placementKey;
//        extras.articlesBeforeFirstAd = [placementJSON[@"articlesBeforeFirstAd"] unsignedIntegerValue];
//        extras.articlesBetweenAds = [placementJSON[@"articlesBetweenAds"] unsignedIntegerValue];
//        [self.adCache saveInfiniteScrollFields:extras];
//
//        if ([placement.delegate respondsToSelector:@selector(adView:didFetchArticlesBeforeFirstAd:andArticlesBetweenAds:forPlacementKey:)]) {
//            [placement.delegate adView:placement.adView didFetchArticlesBeforeFirstAd:extras.articlesBeforeFirstAd andArticlesBetweenAds:extras.articlesBetweenAds forPlacementKey:placement.placementKey];
//        }
//    }
//}

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

@end
