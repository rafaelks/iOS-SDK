#import "STRAdGenerator.h"
#import "STRAdViewFixture.h"
#import "STRAdService.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"
#include "UIImage+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;
    __block STRAdService *adService;

    beforeEach(^{
        [UIGestureRecognizer whitelistClassForGestureSnooping:[STRAdGenerator class]];
        adService = nice_fake_for([STRAdService class]);
        generator = [[STRAdGenerator alloc] initWithPriceKey:@"priceKey" adService:adService];
    });

    describe(@"placing an ad in the view", ^{
        __block STRAdViewFixture *view;
        __block STRDeferred *deferred;
        __block UIActivityIndicatorView *spinner;
        __block UIViewController *presentingViewController;

        beforeEach(^{
            view = [STRAdViewFixture new];
            deferred = [STRDeferred defer];

            presentingViewController = [UIViewController new];
            UIWindow *window = [UIWindow new];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];

            adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(deferred.promise);
            [generator placeAdInView:view placementKey:@"placementKey" presentingViewController:presentingViewController];
            spinner = (UIActivityIndicatorView *) [view.subviews lastObject];
        });

        it(@"shows a spinner while the ad is being fetched", ^{
            spinner should be_instance_of([UIActivityIndicatorView class]);
        });

        it(@"makes a network request", ^{
            adService should have_received(@selector(fetchAdForPlacementKey:)).with(@"placementKey");
        });

        describe(@"when the ad has fetched successfully", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                spy_on(view);

                ad = [STRAdvertisement new];
                ad.adDescription = @"Dogs this smart deserve a home.";
                ad.title = @"Meet Porter. He's a Dog.";
                ad.advertiser = @"Brand X";
                ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];

                [deferred resolveWithValue:ad];
            });

            it(@"removes the spinner", ^{
                spinner.superview should be_nil;
            });

            it(@"fills out the ads' the title, description, and sponsored by", ^{
                view.adTitle.text should equal(@"Meet Porter. He's a Dog.");
                view.adDescription.text should equal(@"Dogs this smart deserve a home.");
                view.adSponsoredBy.text should equal(@"Promoted by Brand X");
            });

            it(@"adds a placeholder image", ^{
                [view.adThumbnail.image isEqualToByBytes:[UIImage imageNamed:@"fixture_image.png"]] should be_truthy;
                view.adThumbnail.contentMode should equal(UIViewContentModeScaleAspectFill);
            });

            it(@"relayouts view because tableviewcells need to have content in subviews to determine dimensions", ^{
                view should have_received(@selector(setNeedsLayout));
            });

            it(@"adds a gesture recognizer for taps", ^{
                [view.gestureRecognizers count] should equal(1);
                [view.gestureRecognizers lastObject] should be_instance_of([UITapGestureRecognizer class]);
            });

            describe(@"when the ad is tapped on", ^{
                __block STRInteractiveAdViewController *interactiveAdController;

                beforeEach(^{
                    [[view.gestureRecognizers lastObject] recognize];
                    interactiveAdController = (STRInteractiveAdViewController *)presentingViewController.presentedViewController;

                });

                it(@"presents the STRInteractiveAdViewController", ^{
                    interactiveAdController should be_instance_of([STRInteractiveAdViewController class]);
                    interactiveAdController.ad should be_same_instance_as(ad);
                    interactiveAdController.delegate should be_same_instance_as(generator);
                });

                it(@"dismisses the interactive ad controller when told", ^{
                    [interactiveAdController.delegate closedInteractiveAdView:interactiveAdController];

                    presentingViewController.presentedViewController should be_nil;
                });
            });
        });

        describe(@"when the ad has fetched successfully", ^{
            beforeEach(^{
                [deferred rejectWithError:[NSError errorWithDomain:@"Error!" code:101 userInfo:nil]];
            });

            it(@"removes the spinner", ^{
                spinner.superview should be_nil;
            });
        });
    });
});

SPEC_END
