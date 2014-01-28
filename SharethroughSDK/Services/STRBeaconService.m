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
    CGRect screenFrame = [[UIScreen mainScreen] bounds];

    NSDictionary *parameters = @{@"pkey": placementKey,
                                 @"type": @"impressionRequest",
                                 @"bwidth": [NSString stringWithFormat:@"%g", CGRectGetWidth(screenFrame)],
                                 @"bheight": [NSString stringWithFormat:@"%g", CGRectGetHeight(screenFrame)],
                                 @"umtime": [NSString stringWithFormat:@"%lli", self.dateProvider.millisecondsSince1970]};

    [self.restClient sendBeaconWithParameters:parameters];
}
@end
