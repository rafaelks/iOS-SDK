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

char const * const STRAdGeneratorKey = "STRAdGeneratorKey";

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

- (void)placeAdInPlacement:(STRAdPlacement *)placement {
    [self addSpinnerToView:placement.adView];

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placement.placementKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        [self.spinner removeFromSuperview];

        STRAdRenderer *renderer = [self.injector getInstance:[STRAdRenderer class]];
        [renderer renderAd:ad inPlacement:placement];

        return ad;
    } error:^id(NSError *error) {
        [self.spinner removeFromSuperview];
        [placement.adView setNeedsLayout];

        if ([placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:)]) {
            [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey];
        }
        return error;
    }];
}

- (STRPromise *)placeCreative:(NSString *)creativeKey inPlacement:(STRAdPlacement *)placement {
    STRDeferred *deferred = [STRDeferred defer];

    STRPromise *adPromise = [self.adService fetchAdForPlacementKey:placement.placementKey creativeKey:creativeKey];
    [adPromise then:^id(STRAdvertisement *ad) {
        STRAdRenderer *renderer = [self.injector getInstance:[STRAdRenderer class]];
        [renderer renderAd:ad inPlacement:placement];
        [deferred resolveWithValue:nil];
        return ad;
    } error:^id(NSError *error) {
        [placement.adView setNeedsLayout];

        if ([placement.delegate respondsToSelector:@selector(adView:didFailToFetchAdForPlacementKey:)]) {
            [placement.delegate adView:placement.adView didFailToFetchAdForPlacementKey:placement.placementKey];
        }
        [deferred rejectWithError:error];
        return error;
    }];

    return deferred.promise;
}

- (STRPromise *)prefetchAdForPlacementKey:(NSString *)placementKey {
    return [self.adService fetchAdForPlacementKey:placementKey];
}

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

@end

