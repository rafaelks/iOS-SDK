//
//  STRAdService.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/20/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"

@interface STRAdService ()

@property (nonatomic, strong) STRRestClient *restClient;
@property (nonatomic, strong) STRNetworkClient *networkClient;

@end

@implementation STRAdService

- (id)initWithRestClient:(STRRestClient *)restClient networkClient:(STRNetworkClient *)networkClient {
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.networkClient = networkClient;
    }

    return self;
}

- (STRPromise *)fetchAdForPlacementKey:(NSString *)placementKey {
    STRDeferred *deferred = [STRDeferred defer];

    STRPromise *adPromise = [self.restClient getWithParameters: @{@"placement_key": placementKey}];
    [adPromise then:^id(NSDictionary *adJSON) {
        NSURL *sanitizedThumbnailURL = [NSURL URLWithString:adJSON[@"thumbnail_url"]];
        if (![sanitizedThumbnailURL scheme]) {
            sanitizedThumbnailURL = [NSURL URLWithString:[NSString stringWithFormat:@"http:%@", adJSON[@"thumbnail_url"]]];
        }

        NSURLRequest *imageRequest = [NSURLRequest requestWithURL:sanitizedThumbnailURL];

        [[self.networkClient get:imageRequest] then:^id(NSData *data) {
            STRAdvertisement *ad = [STRAdvertisement new];
            ad.advertiser = adJSON[@"advertiser"];
            ad.title = adJSON[@"title"];
            ad.adDescription = adJSON[@"description"];
            ad.creativeKey = adJSON[@"creative_key"];
            ad.variantKey = adJSON[@"variant_key"];
            ad.mediaURL = [NSURL URLWithString:adJSON[@"media_url"]];
            ad.shareURL = [NSURL URLWithString:adJSON[@"share_url"]];
            ad.thumbnailImage = [UIImage imageWithData:data];

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

@end
