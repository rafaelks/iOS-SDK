#import "STRAdGenerator.h"

#import "STRAdPlacement.h"
#import "STRAdRenderer.h"
#import "STRAdvertisement.h"
#import "STRAdViewDelegate.h"
#import "STRAppModule.h"
#import "STRAsapService.h"
#import "STRDateProvider.h"
#import "STRDeferred.h"
#import "STRFullAdView.h"
#import "STRInjector.h"
#import "STRInteractiveAdViewController.h"
#import "UIView+Visible.h"
#import <objc/runtime.h>
#include "UIGestureRecognizer+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;
    __block STRAsapService *asapService;
    __block STRAdvertisement *ad;
    __block STRInjector *injector;
    __block STRAdRenderer *renderer;
    __block STRFullAdView *view;
    __block id<STRAdViewDelegate> delegate;
    __block UIViewController *presentingViewController;
    __block UIWindow *window;
    __block STRAdPlacement *placement;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        asapService = nice_fake_for([STRAsapService class]);
        [injector bind:[STRAsapService class] toInstance:asapService];

        renderer = nice_fake_for([STRAdRenderer class]);
        
        [injector bind:[STRAdRenderer class] toInstance:renderer];

        generator = [injector getInstance:[STRAdGenerator class]];

        ad = [STRAdvertisement new];
        ad.adDescription = @"Dogs this smart deserve a home.";
        ad.title = @"Meet Porter. He's a Dog.";
        ad.advertiser = @"Brand X";
        ad.action = STRYouTubeAd;
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
        ad.thirdPartyBeaconsForVisibility = @[@"//google.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForClick = @[@"//click.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForPlay = @[@"//play.com?fakeParam=[timestamp]"];
        ad.placementStatus = @"live";

        view = [STRFullAdView new];

        delegate = nice_fake_for(@protocol(STRAdViewDelegate));

        presentingViewController = [UIViewController new];
        window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        window.rootViewController = presentingViewController;
        [window makeKeyAndVisible];

        placement = [[STRAdPlacement alloc] init];
        placement.adView = view;
        placement.placementKey = @"placementKey";
        placement.presentingViewController = presentingViewController;
        placement.delegate = delegate;
        placement.adIndex = 0;

    });

    describe(@"-placeAdInPlacement", ^{
        __block STRDeferred *deferred;
        __block UIActivityIndicatorView *spinner;

        beforeEach(^{
            deferred = [STRDeferred defer];

            asapService stub_method(@selector(fetchAdForPlacement:isPrefetch:)).and_return(deferred.promise);

            [generator placeAdInPlacement:placement];

            spinner = (UIActivityIndicatorView *) [view.subviews lastObject];
        });

        it(@"shows a spinner while the ad is being fetched", ^{
            spinner should be_instance_of([UIActivityIndicatorView class]);
        });

        it(@"clears out the title, description, and promoted by slug, in case anything has been left there", ^{
            view.adTitle.text should equal(@"");
            view.adDescription.text should equal(@"");
            view.adSponsoredBy.text should equal(@"");
        });

        it(@"makes a request to the ad service", ^{
            asapService should have_received(@selector(fetchAdForPlacement:isPrefetch:)).with(placement, NO);
        });

        describe(@"follows up with its delegate", ^{
            describe(@"on failure", ^{
                subjectAction(^{
                    [deferred rejectWithError:nil];
                });

                context(@"when the delegate has an error callback", ^{
                    it(@"tells the delegate about the error", ^{
                        delegate should have_received(@selector(adView:didFailToFetchAdForPlacementKey:atIndex:))
                        .with(view, @"placementKey", 0);
                    });
                });

                context(@"when the delegate does not have an error callback", ^{
                    beforeEach(^{
                        delegate reject_method(@selector(adView:didFailToFetchAdForPlacementKey:atIndex:));
                    });

                    it(@"does not try to call the delegate", ^{
                        delegate should_not have_received(@selector(adView:didFailToFetchAdForPlacementKey:atIndex:));
                    });
                });
            });
        });

        describe(@"when the ad has fetched successfully", ^{
            beforeEach(^{
                spy_on(view);

                view.frame = CGRectMake(0, 0, 100, 100);
                [deferred resolveWithValue:ad];
            });

            it(@"removes the spinner", ^{
                spinner.superview should be_nil;
            });

            it(@"calls the renderer to place the ad in the view", ^{
                renderer should have_received(@selector(renderAd:inPlacement:)).with(ad, placement);
            });
        });

        describe(@"when the ad fetch fails", ^{
            beforeEach(^{
                [deferred rejectWithError:[NSError errorWithDomain:@"Error!" code:101 userInfo:nil]];
            });

            it(@"removes the spinner", ^{
                spinner.superview should be_nil;
            });
        });
    });

    describe(@"-prefetchAdForPlacement", ^{
        it(@"asks the ad service to prefetch", ^{
            [generator prefetchAdForPlacement:placement];

            asapService should have_received(@selector(fetchAdForPlacement:isPrefetch:)).with(placement, YES);
        });
    });

    describe(@"place an ad in a view without an ad description", ^{
        __block STRPlainAdView *view;
        __block STRDeferred *deferred;

        beforeEach(^{
            view = [STRPlainAdView new];
            deferred = [STRDeferred defer];

            asapService stub_method(@selector(fetchAdForPlacement:isPrefetch:)).and_return(deferred.promise);
            
            STRAdPlacement *placement = [[STRAdPlacement alloc] init];
            placement.adView = view;
            placement.placementKey = @"placementKey";

            [generator placeAdInPlacement:placement];
        });

        it(@"does not try to include an ad description", ^{
            expect(^{
                [deferred resolveWithValue:ad];
            }).to_not(raise_exception);
        });
    });
});

SPEC_END
