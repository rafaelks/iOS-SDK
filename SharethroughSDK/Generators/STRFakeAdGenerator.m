//
//  STRFakeAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRFakeAdGenerator.h"
#import <objc/runtime.h>
#import "STRAdView.h"
#import "STRAdvertisement.h"
#import "STRAdFixtures.h"
#import "STRInteractiveAdViewController.h"
#import "STRNavigationController.h"
#import "STRInjector.h"
#import "STRAppModule.h"

@interface STRFakeAdGenerator () <STRInteractiveAdViewControllerDelegate>
@property (nonatomic, strong) STRAdvertisement *advertisement;
@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) UIViewController *presentingViewController;
@end

@implementation STRFakeAdGenerator

- (id)initWithAdService:(STRAdService *)adService beaconService:(STRBeaconService *)beaconService runLoop:(NSRunLoop *)timerRunLoop injector:(STRInjector *)injector {

    [NSException raise:@"STRFakeAdGeneratorError"
                format:@"Fake ad generator does not respond to %@, because it does not use any of these things.", NSStringFromSelector(_cmd)];
    return nil;
}

- (id)init {
    self = [super init];
    if (self) {
        self.advertisement = [STRAdvertisement new];
        self.advertisement.title = @"Generic Ad Title";
        self.advertisement.advertiser = @"Sharethrough";
        self.advertisement.adDescription = @"Ad description text";
    }
    return self;
}
- (id)initWithAdType:(STRFakeAdType)adType withInjector:(STRInjector *)injector{
    self = [super init];

    self.injector = injector;

    switch (adType) {
        case STRFakeAdTypeYoutube:
            self.advertisement = (STRAdvertisement *)[STRAdFixtures youTubeAd];
            break;
        case STRFakeAdTypeVine:
            self.advertisement = (STRAdvertisement *)[STRAdFixtures vineAd];
            break;
        default:
            break;
    }
    return self;
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {

    objc_setAssociatedObject(view, STRAdGeneratorKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    view.adTitle.text = self.advertisement.title;
    view.adSponsoredBy.text = self.advertisement.sponsoredBy;
    view.adThumbnail.image = [self.advertisement displayableThumbnail];
    if ([view respondsToSelector:@selector(adDescription)]) {
        view.adDescription.text = self.advertisement.adDescription;
    }

    self.presentingViewController = presentingViewController;
    [view setNeedsLayout];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAd:)];
    [view addGestureRecognizer:tapRecognizer];
}


- (void)tappedAd:(UITapGestureRecognizer *)tapRecognizer {

    STRInteractiveAdViewController *adController = [[STRInteractiveAdViewController alloc] initWithAd:self.advertisement
                                                                                               device:[UIDevice currentDevice]
                                                                                        beaconService:nil
                                                                                             injector:self.injector];
    adController.delegate = self;
    STRNavigationController *navController = [[STRNavigationController alloc] initWithRootViewController:adController];
    [self.presentingViewController presentViewController:navController animated:YES completion:nil];
}

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
