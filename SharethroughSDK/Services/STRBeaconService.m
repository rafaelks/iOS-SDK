//
//  STRBeaconService.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/28/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRDateProvider.h"
#import "STRSession.h"
#import <AdSupport/AdSupport.h>
#import "STRAdvertisement.h"

@interface STRBeaconService ()

@property (strong, nonatomic) STRRestClient *restClient;
@property (strong, nonatomic) STRDateProvider *dateProvider;
@property (weak, nonatomic) ASIdentifierManager *identifierManager;

@end

@implementation STRBeaconService

- (id)initWithRestClient:(STRRestClient *)restClient dateProvider:(STRDateProvider *)dateProvider asIdentifierManager:(ASIdentifierManager *)identifierManager {
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.dateProvider = dateProvider;
        self.identifierManager = identifierManager;
    }
    return self;
}

- (void)fireImpressionRequestForPlacementKey:(NSString *)placementKey {
    NSDictionary *uniqueParameters = @{@"pkey": placementKey,
                                       @"type": @"impressionRequest"};
    NSMutableDictionary *parameters = [self commonParameters];
    [parameters addEntriesFromDictionary:uniqueParameters];

    [self.restClient sendBeaconWithParameters:parameters];
}

- (void)fireVisibleImpressionForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    if (!ad.visibleImpressionBeaconFired) {
        ad.visibleImpressionBeaconFired = YES;
        NSDictionary *uniqueParameters = @{@"type": @"visible"};

        NSMutableDictionary *parameters = [self impressionParametersForAd:ad adSize:adSize];
        [parameters addEntriesFromDictionary:uniqueParameters];

        [self.restClient sendBeaconWithParameters:parameters];
    }
}

- (void)fireImpressionForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    if (!ad.impressionBeaconFired) {
        ad.impressionBeaconFired = YES;
        NSDictionary *uniqueParameters = @{@"type": @"impression"};

        NSMutableDictionary *parameters = [self impressionParametersForAd:ad adSize:adSize];
        [parameters addEntriesFromDictionary:uniqueParameters];

        [self.restClient sendBeaconWithParameters:parameters];
    }
}

- (void)fireThirdPartyBeacons:(NSArray *)beaconPaths {
    NSString *timeStamp = [NSString stringWithFormat:@"%lli", [self.dateProvider millisecondsSince1970]];
    for (NSString *urlStub in beaconPaths) {
        NSMutableString *urlString = [urlStub mutableCopy];
        NSRange timeStampRange = [urlString rangeOfString:@"[timestamp]"];
        if (timeStampRange.location != NSNotFound ) {
            [urlString replaceCharactersInRange:timeStampRange withString:timeStamp];
        }
        [urlString insertString:@"http:" atIndex:0];
        [self.restClient sendBeaconWithURL:[NSURL URLWithString:urlString]];
    }
}

- (void)fireVideoPlayEvent:(STRAdvertisement *)ad adSize:(CGSize)size {
    NSString *userEvent = @"videoPlay";
    if ([ad.action isEqualToString:STRYouTubeAd]) {
        userEvent = @"youtubePlay";
    } else if ([ad.action isEqualToString:STRVineAd]) {
        userEvent = @"vinePlay";
    }

    NSDictionary *uniqueParameters = @{@"type": @"userEvent",
                                       @"userEvent": userEvent,
                                       @"engagement": @"true"};

    NSMutableDictionary *parameters = [self impressionParametersForAd:ad adSize:size];
    [parameters addEntriesFromDictionary:uniqueParameters];
    [self.restClient sendBeaconWithParameters:parameters];
}

- (void)fireVideoCompletionForAd:(STRAdvertisement *)ad completionPercent:(NSNumber *)completionPercent {
    NSDictionary *uniqueParameters = @{@"type": @"completionPercent",
                                       @"value": completionPercent};

    NSMutableDictionary *parameters = [self commonParametersWithAd:ad];
    [parameters addEntriesFromDictionary:uniqueParameters];
    [self.restClient sendBeaconWithParameters:parameters];
}

- (void)fireShareForAd:(STRAdvertisement *)ad shareType:(NSString *)uiActivityType {
    NSDictionary *knownShareTypes = @{UIActivityTypeMail: @"email",
                                           UIActivityTypePostToFacebook: @"facebook",
                                           UIActivityTypePostToTwitter: @"twitter"};
    NSString *shareType = knownShareTypes[uiActivityType] ? knownShareTypes[uiActivityType] : uiActivityType ;

    NSDictionary *uniqueParameters = @{@"type": @"userEvent",
                                       @"userEvent": @"share",
                                       @"share": shareType,
                                       @"engagement": @"true"};
    NSMutableDictionary *parameters = [self commonParametersWithAd:ad];
    [parameters addEntriesFromDictionary:uniqueParameters];

    [self.restClient sendBeaconWithParameters:parameters];

}

- (void)fireClickForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    NSDictionary *uniqueParameters = @{@"type": @"userEvent",
                                       @"userEvent": @"clickout",
                                       @"engagement": @"true"};

    NSMutableDictionary *parameters = [self impressionParametersForAd:ad adSize:adSize];
    [parameters addEntriesFromDictionary:uniqueParameters];
    [self.restClient sendBeaconWithParameters:parameters];
}

#pragma mark - Private

- (NSMutableDictionary *)impressionParametersForAd:(STRAdvertisement *)ad adSize:(CGSize)adSize {
    NSMutableDictionary *params = [@{@"pwidth": [NSString stringWithFormat:@"%g", adSize.width],
                                     @"pheight": [NSString stringWithFormat:@"%g", adSize.height]}
                                   mutableCopy];
    [params addEntriesFromDictionary:[self commonParametersWithAd:ad]];

    return params;
}

- (NSMutableDictionary *)commonParametersWithAd:(STRAdvertisement *)ad {
    NSDictionary *adParams = @{@"pkey": ad.placementKey,
                               @"vkey": ad.variantKey,
                               @"ckey": ad.creativeKey,
                               @"as": ad.signature,
                               @"at": ad.auctionType,
                               @"ap": ad.auctionPrice};
    NSMutableDictionary *commonParams = [self commonParameters];
    [commonParams addEntriesFromDictionary:adParams];

    return commonParams;
}

- (NSMutableDictionary *)commonParameters{
    CGRect screenFrame = [[UIScreen mainScreen] bounds];

    return [@{@"bwidth" : [NSString stringWithFormat:@"%g", CGRectGetWidth(screenFrame)],
              @"bheight": [NSString stringWithFormat:@"%g", CGRectGetHeight(screenFrame)],
              @"umtime" : [NSString stringWithFormat:@"%lli", self.dateProvider.millisecondsSince1970],
              @"ploc"   : [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey],
              @"session": [STRSession sessionToken],
              @"uid"    : [[self.identifierManager advertisingIdentifier] UUIDString],
              @"ua"     : [self.restClient getUserAgent]} mutableCopy];
}

@end
