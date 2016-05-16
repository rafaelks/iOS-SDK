//
//  STRAdGenerator.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/16/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRAdGenerator.h"

#import <objc/runtime.h>

#import "STRAdPlacement.h"
#import "STRAdRenderer.h"
#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRAdViewDelegate.h"
#import "STRAsapService.h"
#import "STRDeferred.h"
#import "STRInjector.h"
#import "STRLogging.h"
#import "STRPromise.h"

@interface STRAdGenerator ()

@property (nonatomic, strong) STRAsapService *asapService;
@property (nonatomic, weak) STRInjector *injector;

@property (nonatomic, weak) UIView *spinner;

@end

@implementation STRAdGenerator

- (id)initWithAsapService:(STRAsapService *)asapService
                 injector:(STRInjector *)injector
{
    self = [super init];
    if (self) {
        self.asapService = asapService;
        self.injector = injector;
    }
    return self;
}

- (STRPromise *)placeAdInPlacement:(STRAdPlacement *)placement {
    TLog(@"pkey:%@",placement.placementKey);

    STRDeferred *deferred = [STRDeferred defer];
    [self addSpinnerToView:placement.adView];
    [self clearTextFromView:placement.adView];

    STRPromise *adPromise;
    adPromise = [self.asapService fetchAdForPlacement:placement isPrefetch:NO];

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
    return [self.asapService fetchAdForPlacement:placement isPrefetch:YES];
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

