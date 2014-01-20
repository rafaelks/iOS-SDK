//
//  STRAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdGenerator.h"
#import "STRAdView.h"
#import "STRRestClient.h"
#import "STRPromise.h"

@interface STRAdGenerator ()

@property (nonatomic, weak) STRRestClient *restClient;

@end

@implementation STRAdGenerator

- (id)initWithPriceKey:(NSString *)priceKey restClient:(STRRestClient *)restClient {
    self = [super init];
    if (self) {
        self.restClient = restClient;
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [view addSubview:spinner];
    [spinner startAnimating];
    spinner.center = view.center;

    STRPromise *adPromise = [self.restClient getWithParameters: @{@"placement_key": placementKey}];
    [adPromise then:^id(NSDictionary *adJSON) {
        [spinner removeFromSuperview];

        view.adTitle.text = adJSON[@"title"];
        view.adDescription.text = adJSON[@"description"];
        view.adSponsoredBy.text = [NSString stringWithFormat:@"Promoted by %@", adJSON[@"advertiser"]];
        view.adThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        view.adThumbnail.image = [self fixtureImage];

        return adJSON;
    } error:^id(NSError *error) {
        [spinner removeFromSuperview];
        return error;
    }];
}

- (BOOL)runningInFramework {
    return [[NSBundle mainBundle] pathForResource:@"Sharethrough-SDK.framework" ofType:nil] != nil;
}

- (UIImage *)fixtureImage {
    NSString *path;
    if ([self runningInFramework]) {
        path = [[NSBundle mainBundle] pathForResource:@"Sharethrough-SDK.framework/Resources/STRResources.bundle/images/fixture_image.png" ofType:nil];
    } else {
        path = [[NSBundle mainBundle] pathForResource:@"STRResources.bundle/images/fixture_image.png" ofType:nil];
    }

    return [UIImage imageWithContentsOfFile:path];

}
@end

