#import "STRAdGenerator.h"
#import "STRAdViewFixture.h"
#import "STRAdService.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "NSTimer+Spec.h"
#import "STRInjector.h"
#import "STRAppModule.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;
    __block STRAdService *adService;
    __block STRBeaconService *beaconService;
    __block STRAdvertisement *ad;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule moduleWithStaging:NO]];

        [UIGestureRecognizer whitelistClassForGestureSnooping:[STRAdGenerator class]];

        adService = nice_fake_for([STRAdService class]);
        [injector bind:[STRAdService class] toInstance:adService];

        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        generator = [injector getInstance:[STRAdGenerator class]];

        ad = [STRAdvertisement new];
        ad.adDescription = @"Dogs this smart deserve a home.";
        ad.title = @"Meet Porter. He's a Dog.";
        ad.advertiser = @"Brand X";
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
    });

    afterEach(^{
        [NSTimer clear];
    });

    describe(@"placing an ad in the view", ^{
        __block STRAdViewFixture *view;
        __block STRDeferred *deferred;
        __block UIActivityIndicatorView *spinner;
        __block UIViewController *presentingViewController;
        __block UIWindow *window;

        beforeEach(^{
            view = [STRAdViewFixture new];
            deferred = [STRDeferred defer];

            presentingViewController = [UIViewController new];
            window = [UIWindow new];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];

            adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(deferred.promise);
            beaconService stub_method(@selector(fireImpressionRequestForPlacementKey:));

            [generator placeAdInView:view placementKey:@"placementKey" presentingViewController:presentingViewController];
            spinner = (UIActivityIndicatorView *) [view.subviews lastObject];
        });

        it(@"stores the itself (the generator) as an associated object of the view", ^{
            objc_getAssociatedObject(view, kAdGeneratorKey) should be_same_instance_as(generator);
        });

        it(@"fires an impressionRequest to the beacon", ^{
            beaconService should have_received(@selector(fireImpressionRequestForPlacementKey:)).with(@"placementKey");
        });

        it(@"shows a spinner while the ad is being fetched", ^{
            spinner should be_instance_of([UIActivityIndicatorView class]);
        });

        it(@"clears out the title, description, and promoted by slug, in case anything has been left there", ^{
            view.adTitle.text should equal(@"");
            view.adDescription.text should equal(@"");
            view.adSponsoredBy.text should equal(@"");
        });

        it(@"makes a network request", ^{
            adService should have_received(@selector(fetchAdForPlacementKey:)).with(@"placementKey");
        });

        describe(@"when the ad has fetched successfully", ^{
            beforeEach(^{
                spy_on(view);

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

            it(@"adds the ad's image", ^{
                char imageData[100];
                [UIImagePNGRepresentation(view.adThumbnail.image) getBytes:&imageData length:100];

                char expectedData[100];
                [UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]) getBytes:&expectedData length:100];
                imageData should equal(expectedData);
            });

            it(@"relayouts view because tableviewcells need to have content in subviews to determine dimensions", ^{
                view should have_received(@selector(setNeedsLayout));
            });

            it(@"adds a gesture recognizer for taps", ^{
                [view.gestureRecognizers count] should equal(1);
                [view.gestureRecognizers lastObject] should be_instance_of([UITapGestureRecognizer class]);
            });

            describe(@"view position timer", ^{
                __block NSTimer *timer;

                beforeEach(^{
                    UIView *superView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
                    [window addSubview:superView];
                    [superView addSubview:view];

                    timer = nice_fake_for([NSTimer class]);
                    timer stub_method(@selector(userInfo)).and_return([NSTimer userInfo]);
                });

                it(@"begins a timer", ^{
                    [NSTimer target] should equal(generator);
                });

                context(@"when ad is visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 0, 100, 100);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [[NSTimer target] performSelector:[NSTimer action] withObject:timer];
#pragma clang diagnostic pop
                    });

                    it(@"should send a beacon", ^{
                        beaconService should have_received(@selector(fireVisibleImpressionForPlacementKey:));
                    });

                    it(@"invalidates timer", ^{
                        timer should have_received(@selector(invalidate));
                    });
                });

                context(@"when ad is not visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 481, 320, 500);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [[NSTimer target] performSelector:[NSTimer action] withObject:timer];
#pragma clang diagnostic pop

                    });

                    it(@"does not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForPlacementKey:));
                    });

                    it(@"does not invalidate the timer", ^{
                        [NSTimer isRepeating] should be_truthy;
                        timer should_not have_received(@selector(invalidate));
                    });
                });

                context(@"after the ad is removed from its superview", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 481, 320, 500);
                        [view removeFromSuperview];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [[NSTimer target] performSelector:[NSTimer action] withObject:timer];
#pragma clang diagnostic pop
                    });

                    it(@"invalidates its timer", ^{
                        timer should have_received(@selector(invalidate));
                    });

                    it(@"does not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForPlacementKey:));
                    });
                });
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

        describe(@"when the view has already had an ad placed within it", ^{
            __block STRAdGenerator *secondGenerator;

            beforeEach(^{
                [deferred resolveWithValue:ad];

                secondGenerator = [[STRAdGenerator alloc] initWithAdService:adService beaconService:beaconService];
                [secondGenerator placeAdInView:view placementKey:@"key" presentingViewController:presentingViewController];
            });

            it(@"should have cleaned up old tap gesture recognizers", ^{
                [view.gestureRecognizers count] should equal(1);
            });
        });
    });

    describe(@"place an ad in a view without an ad description", ^{
        __block STRMinimalAdViewFixture *view;
        __block STRDeferred *deferred;

        beforeEach(^{
            view = [STRMinimalAdViewFixture new];
            deferred = [STRDeferred defer];

            adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(deferred.promise);
            [generator placeAdInView:view placementKey:@"placementKey" presentingViewController:nil];
        });

        it(@"does not try to include an ad description", ^{
            expect(^{
                [deferred resolveWithValue:ad];
            }).to_not(raise_exception);
        });
    });
});

SPEC_END
