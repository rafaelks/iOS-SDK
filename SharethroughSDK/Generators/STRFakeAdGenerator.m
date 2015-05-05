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
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRDeferred.h"
#import "STRAdPlacement.h"

@interface STRFakeAdGenerator () <STRInteractiveAdViewControllerDelegate>
@property (nonatomic, strong) STRAdvertisement *advertisement;
@property (nonatomic, strong) STRInjector *injector;
@property (nonatomic, strong) STRAdPlacement *placement;
@property (nonatomic, strong) UIViewController *presentingViewController;
@property (nonatomic, weak) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, weak) UITapGestureRecognizer *disclosureTapRecognizer;
@end

@implementation STRFakeAdGenerator

- (id)initWithAdService:(STRAdService *)adService injector:(STRInjector *)injector {

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
        case STRFakeAdTypeHostedVideo:
            self.advertisement = (STRAdvertisement *)[STRAdFixtures hostedVideoAd];
            break;
        case STRFakeAdTypeClickout:
            self.advertisement = (STRAdvertisement *)[STRAdFixtures clickoutAd];
            break;
        case STRFakeAdTypePinterest:
            self.advertisement = (STRAdvertisement *)[STRAdFixtures pinterestAd];
            break;
        case STRFakeAdTypeInstagram:
            self.advertisement = (STRAdvertisement *)[STRAdFixtures instagramAd];
            break;
        default:
            break;
    }
    return self;
}

- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement {
    STRDeferred *deferred = [STRDeferred defer];
    self.placement = placement;
    [deferred resolveWithValue:nil];
    [self placeAdInView:placement.adView
           placementKey:placement.placementKey
presentingViewController:placement.presentingViewController
               delegate:placement.delegate];
    return deferred.promise;
}

- (void)placeAdInView:(UIView<STRAdView> *)view
         placementKey:(NSString *)placementKey
presentingViewController:(UIViewController *)presentingViewController
             delegate:(id<STRAdViewDelegate>)delegate {

    [self prepareForNewAd:view];

    objc_setAssociatedObject(view, @"FakeRenderer", self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    view.adTitle.text = self.advertisement.title;
    view.adSponsoredBy.text = self.advertisement.sponsoredBy;
    view.adThumbnail.image = [self.advertisement displayableThumbnail];
    [view.adThumbnail addSubview:[self.advertisement platformLogoForWidth:view.adThumbnail.frame.size.width]];

    if ([view respondsToSelector:@selector(adDescription)]) {
        view.adDescription.text = self.advertisement.adDescription;
    }
    if ([view respondsToSelector:@selector(adBrandLogo)] && self.advertisement.brandLogoImage != nil) {
        view.adBrandLogo.image = self.advertisement.brandLogoImage;
    }

    if (view.disclosureButton.buttonType != 2) {
        [NSException raise:@"STRDiscloseButtonType" format:@"The disclosure button provided by the STRAdView is not of type UIButtonTypeDetailDisclosure"];
    }
    UITapGestureRecognizer *disclosureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedFakeDisclosureBtn)];
    [view.disclosureButton addGestureRecognizer:disclosureRecognizer];
    self.disclosureTapRecognizer = disclosureRecognizer;

    self.presentingViewController = presentingViewController;
    [view setNeedsLayout];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedFakeAd:)];
    [view addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;

    if ([delegate respondsToSelector:@selector(adView:didFetchAdForPlacementKey:atIndex:)]) {
        [delegate adView:view didFetchAdForPlacementKey:placementKey atIndex:0];
    }
}

- (void)tappedFakeAd:(UITapGestureRecognizer *)tapRecognizer {
    STRInteractiveAdViewController *adController = [[STRInteractiveAdViewController alloc] initWithAd:self.advertisement
                                                                                               device:[UIDevice currentDevice]
                                                                                          application:[UIApplication sharedApplication]
                                                                                        beaconService:nil
                                                                                             injector:self.injector];
    if ([self.placement.delegate respondsToSelector:@selector(adView:userDidEngageAdForPlacementKey:)]) {
        [self.placement.delegate adView:self.placement.adView userDidEngageAdForPlacementKey:self.placement.placementKey];
    }
    adController.delegate = self;
    [self.presentingViewController presentViewController:adController animated:YES completion:nil];
}

- (IBAction)tappedFakeDisclosureBtn
{
    STRInteractiveAdViewController *adController = [[STRInteractiveAdViewController alloc] initWithAd:(STRAdvertisement *)[STRAdFixtures privacyInformationAd]
                                                                                               device:[UIDevice currentDevice]
                                                                                          application:[UIApplication sharedApplication]
                                                                                        beaconService:nil
                                                                                             injector:self.injector];
    adController.delegate = self;
    [self.presentingViewController presentViewController:adController animated:YES completion:nil];
}

- (void)closedInteractiveAdView:(STRInteractiveAdViewController *)adController {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (STRPromise *)prefetchAdForPlacement:(STRAdPlacement *)placement {
    STRDeferred *deferred = [STRDeferred defer];
    [deferred resolveWithValue:nil];
    return deferred.promise;
}

- (NSInteger)numberOfAdsForPlacement:(STRAdPlacement *)placement{
    return 1;
}

- (void)prepareForNewAd:(UIView<STRAdView> *)view {
    STRFakeAdGenerator *oldGenerator = objc_getAssociatedObject(view, @"FakeRenderer");
    [view removeGestureRecognizer:oldGenerator.tapRecognizer];
    [view.disclosureButton removeGestureRecognizer:oldGenerator.disclosureTapRecognizer];
}
@end
