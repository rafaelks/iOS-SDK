//
//  STRAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdGenerator.h"

#import <objc/runtime.h>

#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRAdPlacement.h"
#import "STRAdRenderer.h"
#import "STRAdViewDelegate.h"
#import "STRDeferred.h"
#import "STRInjector.h"
#import "STRPromise.h"

@interface STRAdGenerator ()

@property (nonatomic, strong) STRAdService *adService;
@property (nonatomic, weak) STRInjector *injector;

@property (nonatomic, weak) UIView *spinner;

@end

@implementation STRAdGenerator

- (id)initWithAdService:(STRAdService *)adService
               injector:(STRInjector *)injector
{
    self = [super init];
    if (self) {
        self.adService = adService;
        self.injector = injector;
    }
    return self;
}

- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement {
    return [self placeCreative:@"" inPlacement:placement];
}

- (STRPromise *)placeCreative:(NSString *)creativeKey inPlacement:(STRAdPlacement *)placement {
    STRDeferred *deferred = [STRDeferred defer];
    [self addSpinnerToView:placement.adView];
    [self clearTextFromView:placement.adView];

    STRPromise *adPromise;
    if ([creativeKey length] > 0){
        adPromise = [self.adService fetchAdForPlacement:placement creativeKey:creativeKey];
    } else {
        adPromise = [self.adService fetchAdForPlacement:placement];
    }

    [adPromise then:^id(STRAdvertisement *ad) {
        [self.spinner removeFromSuperview];

        STRAdRenderer *renderer = [self.injector getInstance:[STRAdRenderer class]];
        [renderer renderAd:ad inPlacement:placement];

        [deferred resolveWithValue:nil];
        return ad;
    } error:^id(NSError *error) {
        [self.spinner removeFromSuperview];
        [placement.adView setNeedsLayout];

        if (error.code != kRequestInProgress && [placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:atIndex:)]) {
            [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey atIndex:placement.adIndex];
        }
        [deferred rejectWithError:error];
        return error;
    }];

    return deferred.promise;
}

- (STRPromise *)prefetchAdForPlacement:(STRAdPlacement *)placement {
    return [self.adService prefetchAdsForPlacement:placement];
}

- (STRPromise *)prefetchCreative:(NSString *)creativeKey forPlacement:(STRAdPlacement *)placement {
    return [self.adService fetchAdForPlacement:placement creativeKey:creativeKey];
}

- (NSInteger)numberOfAdsForPlacement:(STRAdPlacement *)placement {
    return [self.adService numberOfAdsForPlacement:placement];
}

#pragma mark - Private

- (void)addSpinnerToView:(UIView *)view {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:spinner];
    [spinner startAnimating];
    [self centerView:spinner toView:view];
    self.spinner = spinner;
}

- (void)centerView:(UIView *)viewToCenter toView:(UIView *)referenceView {
    [referenceView addConstraint:[NSLayoutConstraint constraintWithItem:viewToCenter
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:referenceView
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0
                                                               constant:0]];
    [referenceView addConstraint:[NSLayoutConstraint constraintWithItem:viewToCenter
                                                              attribute:NSLayoutAttributeCenterY
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:referenceView
                                                              attribute:NSLayoutAttributeCenterY
                                                             multiplier:1.0
                                                               constant:0]];
}

- (void)clearTextFromView:(UIView<STRAdView> *)view {
    view.adTitle.text = @"";
    view.adSponsoredBy.text = @"";
    [self setDescriptionText:@"" onView:view];
    view.adThumbnail.image = nil;
}

- (void)setDescriptionText:(NSString *)text onView:(UIView<STRAdView> *)view {
    if ([view respondsToSelector:@selector(adDescription)]) {
        view.adDescription.text = text;
    }
}

@end

