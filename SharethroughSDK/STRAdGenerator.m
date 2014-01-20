//
//  STRAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdGenerator.h"
#import "STRAdView.h"
#import "STRAdService.h"
#import "STRPromise.h"
#import "STRAdvertisement.h"

@interface STRAdGenerator ()

@property (nonatomic, weak) STRAdService *adService;

@end

@implementation STRAdGenerator

- (id)initWithPriceKey:(NSString *)priceKey adService:(STRAdService *)adService {
    self = [super init];
    if (self) {
        self.adService = adService;
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view placementKey:(NSString *)placementKey {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [view addSubview:spinner];
    [spinner startAnimating];
    spinner.center = view.center;

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placementKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        [spinner removeFromSuperview];

        view.adTitle.text = ad.title;
        view.adDescription.text = ad.adDescription;
        view.adSponsoredBy.text = [ad sponsoredBy];
        view.adThumbnail.contentMode = UIViewContentModeScaleAspectFill;
        view.adThumbnail.image = ad.thumbnailImage;

        return ad;
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

