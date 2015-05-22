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
#import "STRLogging.h"

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
    TLog(@"pkey:%@",placement.placementKey);
    return [self placeAdInPlacement:placement auctionParameterKey:nil auctionParameterValue:nil];
}

- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement auctionParameterKey:(NSString *)apKey auctionParameterValue:(NSString *)apValue {
    TLog(@"pkey:%@ apKey:%@, apValue%@",placement.placementKey, apKey, apValue);
    STRDeferred *deferred = [STRDeferred defer];
    [self addSpinnerToView:placement.adView];
    [self clearTextFromView:placement.adView];

    STRPromise *adPromise;
    if (apKey && apValue && apKey.length > 0 && apValue.length > 0){
        adPromise = [self.adService fetchAdForPlacement:placement auctionParameterKey:apKey auctionParameterValue:apValue];
    } else {
        adPromise = [self.adService fetchAdForPlacement:placement];
    }

    [adPromise then:^id(STRAdvertisement *ad) {
        TLog(@"Generator received ckey:%@", ad.creativeKey);
        [self.spinner removeFromSuperview];

        STRAdRenderer *renderer = [self.injector getInstance:[STRAdRenderer class]];
        [renderer renderAd:ad inPlacement:placement];

        [deferred resolveWithValue:nil];
        return ad;
    } error:^id(NSError *error) {
        TLog(@"Genreator did not receive ad");
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
    TLog(@"pkey:%@",placement.placementKey);
    return [self.adService prefetchAdsForPlacement:placement];
}

- (STRPromise *)prefetchForPlacement:(STRAdPlacement *)placement auctionParameterKey:(NSString *)apKey auctionParameterValue:(NSString *)apValue {
    TLog(@"pkey:%@ apKey:%@, apValue%@",placement.placementKey, apKey, apValue);
    return [self.adService fetchAdForPlacement:placement auctionParameterKey:apKey auctionParameterValue:apValue];
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

