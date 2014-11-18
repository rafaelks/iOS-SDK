#import "STRSpecModule.h"
#import <objc/runtime.h>

#import "STRDFPAdGenerator.h"
#import "STRInjector.h"
#import "STRAdService.h"
#import "STRRestClient.h"
#import "STRDFPAppModule.h"
#import "STRAdRenderer.h"
#import "STRAdPlacement.h"
#import "STRDeferred.h"
#import "STRFullAdView.h"
#import "STRDFPManager.h"

#import "GADBannerView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRDFPAdGeneratorSpec)

describe(@"DFPAdGenerator", ^{
    __block STRDFPAdGenerator *generator;
    __block STRAdService *adService;
    __block STRInjector *injector;
    __block STRRestClient *restClient;
    __block STRAdRenderer *renderer;
    __block STRAdPlacement *adPlacement;
    __block STRDeferred *deferred;
    __block id<STRAdViewDelegate> delegate;
    __block STRFullAdView *view;

    beforeEach(^{
        deferred = [STRDeferred defer];
        injector = [STRInjector injectorForModule:[STRDFPAppModule new]];

        adService = nice_fake_for([STRAdService class]);
        [injector bind:[STRAdService class] toInstance:adService];

        restClient = nice_fake_for([STRRestClient class]);
        [injector bind:[STRRestClient class] toInstance:restClient];

        restClient stub_method(@selector(getDFPPathForPlacement:)).and_return(deferred.promise);

        renderer = nice_fake_for([STRAdRenderer class]);
        [injector bind:[STRAdRenderer class] toInstance:renderer];

        delegate = nice_fake_for(@protocol(STRAdViewDelegate));

        view = nice_fake_for([STRFullAdView class]);

        adPlacement = [[STRAdPlacement alloc] initWithAdView:view
                                                PlacementKey:@"placementKey"
                                    presentingViewController:nil
                                                    delegate:delegate
                                                     DFPPath:nil
                                                 DFPDeferred:nil];

        generator = [[STRDFPAdGenerator alloc] initWithAdService:adService injector:injector restClient:restClient];
    });

    context(@"when there is no ad cached", ^{
        beforeEach(^{
            adService stub_method(@selector(isAdCachedForPlacementKey:)).and_return(NO);
        });

        describe(@"when the DFP Path is passed in", ^{
            beforeEach(^{
                adPlacement.DFPPath = @"/this/is/a/path/for/DFP";
                [generator placeAdInPlacement:adPlacement];
            });

            it(@"does not call the rest client", ^{
                restClient should_not have_received(@selector(getDFPPathForPlacement:)).with(adPlacement.placementKey);
            });
        });

        describe(@"successfully fetching the DFP Path from Bakery", ^{
            beforeEach(^{
                [generator placeAdInPlacement:adPlacement];
                [deferred resolveWithValue:@"DFP-Path"];
            });

            it(@"makes a request to bakery if not cached", ^{
                restClient should have_received(@selector(getDFPPathForPlacement:)).with(adPlacement.placementKey);
            });

            it(@"adds the DFP banner view", ^{
                view should have_received(@selector(addSubview:));
            });
        });

        describe(@"fetched an empty DFP Path from Bakery", ^{
            beforeEach(^{
                [generator placeAdInPlacement:adPlacement];
            });

            it(@"notified the delegate that an ad could not be placed", ^{
                [deferred resolveWithValue:@""];
                delegate should have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
            });

            context(@"when the delegate does not have an error callback", ^{
                beforeEach(^{
                    delegate reject_method(@selector(adView:didFailToFetchAdForPlacementKey:));
                });

                it(@"does not try to call the delegate", ^{
                    [deferred resolveWithValue:@""];
                    delegate should_not have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
                });
            });
        });

        describe(@"failed to fetch the DFP Path from Bakery", ^{
            beforeEach(^{
                [generator placeAdInPlacement:adPlacement];
            });

            it(@"notified the delegate that an ad could not be placed", ^{
                [deferred rejectWithError:nil];
                delegate should have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
            });

            context(@"when the delegate does not have an error callback", ^{
                beforeEach(^{
                    delegate reject_method(@selector(adView:didFailToFetchAdForPlacementKey:));
                });

                it(@"does not try to call the delegate", ^{
                    [deferred rejectWithError:nil];
                    delegate should_not have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
                });
            });
        });

        describe(@"when the DFP Path is cached", ^{
            beforeEach(^{
                [generator placeAdInPlacement:adPlacement];
                [deferred resolveWithValue:@"DFP-Path"];
                [(id<CedarDouble>)restClient reset_sent_messages];
                [generator placeAdInPlacement:adPlacement];
            });

            it(@"does not call the rest client", ^{
                restClient should_not have_received(@selector(getDFPPathForPlacement:)).with(adPlacement.placementKey);
            });
        });
    });

    context(@"when there is an ad cached", ^{
        beforeEach(^{
            adService stub_method(@selector(isAdCachedForPlacementKey:)).and_return(YES);
        });

        describe(@"when the placement deferred is set", ^{
            __block STRDeferred *placementDeferred;
            beforeEach(^{
                placementDeferred = nice_fake_for([STRDeferred class]);
                adPlacement.DFPDeferred = placementDeferred;
                [generator placeAdInPlacement:adPlacement];
            });

            it(@"resolves the deferred", ^{
                placementDeferred should have_received(@selector(resolveWithValue:)).with(nil);
            });
        });

        describe(@"when the placement deferred is not set", ^{
            __block STRDeferred *adServiceDeferred;

            beforeEach(^{
                adServiceDeferred = [STRDeferred defer];
                adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(adServiceDeferred.promise);
                [generator placeAdInPlacement:adPlacement];
            });

            it(@"calls the ad service to fetch the ad", ^{
                adService should have_received(@selector(fetchAdForPlacementKey:)).with(adPlacement.placementKey);
            });

            it(@"calls the renderer to render the ad", ^{
                [adServiceDeferred resolveWithValue:nil];
                renderer should have_received(@selector(renderAd:inPlacement:));
            });

            it(@"informs the delegate if it fails", ^{
                [adServiceDeferred rejectWithError:nil];
                delegate should have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
            });
        });
    });

    context(@"GAdBannerViewDelegate", ^{
        __block GADBannerView *gBannerView;
        __block STRDFPManager *dfpManager;

        beforeEach(^{
            gBannerView = nice_fake_for([GADBannerView class]);
            gBannerView stub_method(@selector(adUnitID)).and_return(@"DFPPath");

            dfpManager = [STRDFPManager sharedInstance];
            adPlacement.DFPPath = @"DFPPath";
            [dfpManager cacheAdPlacement:adPlacement];
        });

        describe(@"when the DFP request fails", ^{
            it(@"calls the DFP Manager to infrom the delegate", ^{
                [generator adView:gBannerView didFailToReceiveAdWithError:nil];
                delegate should have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
            });
        });
    });
});

SPEC_END
