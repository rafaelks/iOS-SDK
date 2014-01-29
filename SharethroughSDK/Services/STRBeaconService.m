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

@interface STRBeaconService ()

@property (strong, nonatomic) STRRestClient *restClient;
@property (strong, nonatomic) STRDateProvider *dateProvider;

@end

@implementation STRBeaconService

- (id)initWithRestClient:(STRRestClient *)restClient dateProvider:(STRDateProvider *)dateProvider{
    self = [super init];
    if (self) {
        self.restClient = restClient;
        self.dateProvider = dateProvider;
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


- (void)fireVisibleImpressionForPlacementKey:(NSString *)placementKey {
    NSDictionary *uniqueParameters = @{@"pkey": placementKey,
                                       @"type": @"visible"};
    NSMutableDictionary *parameters = [self commonParameters];
    [parameters addEntriesFromDictionary:uniqueParameters];

    [self.restClient sendBeaconWithParameters:parameters];
}

#pragma mark - Private

- (NSMutableDictionary *)commonParameters {
    CGRect screenFrame = [[UIScreen mainScreen] bounds];

    return [@{ @"bwidth" : [NSString stringWithFormat:@"%g", CGRectGetWidth(screenFrame)],
              @"bheight": [NSString stringWithFormat:@"%g", CGRectGetHeight(screenFrame)],
              @"umtime" : [NSString stringWithFormat:@"%lli", self.dateProvider.millisecondsSince1970],
              @"session": [STRSession sessionToken],
              @"uid"    : [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]} mutableCopy];
}

@end
