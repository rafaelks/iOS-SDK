#import "STRAdGenerator.h"
#import "STRFullAdView.h"
#import "STRAdService.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdViewDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;
    __block STRAdService *adService;
    __block STRBeaconService *beaconService;
    __block STRAdvertisement *ad;
    __block STRInjector *injector;
    __block NSRunLoop<CedarDouble> *fakeRunLoop;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        [UIGestureRecognizer whitelistClassForGestureSnooping:[STRAdGenerator class]];

        adService = nice_fake_for([STRAdService class]);
        [injector bind:[STRAdService class] toInstance:adService];

        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        fakeRunLoop = nice_fake_for([NSRunLoop class]);
        [injector bind:[NSRunLoop class] toInstance:fakeRunLoop];

        generator = [injector getInstance:[STRAdGenerator class]];

        ad = [STRAdvertisement new];
        ad.adDescription = @"Dogs this smart deserve a home.";
        ad.title = @"Meet Porter. He's a Dog.";
        ad.advertiser = @"Brand X";
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
        ad.thirdPartyBeaconsForVisibility = @[@"//google.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForClick = @[@"//click.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForPlay = @[@"//play.com?fakeParam=[timestamp]"];
    });

    describe(@"placing an ad in the view", ^{
        __block STRFullAdView *view;
        __block STRDeferred *deferred;
        __block UIActivityIndicatorView *spinner;
        __block UIViewController *presentingViewController;
        __block UIWindow *window;
        __block id<STRAdViewDelegate> delegate;

        beforeEach(^{
            view = [STRFullAdView new];
            deferred = [STRDeferred defer];

            presentingViewController = [UIViewController new];
            window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];

            adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(deferred.promise);
            beaconService stub_method(@selector(fireImpressionRequestForPlacementKey:));

            delegate = nice_fake_for(@protocol(STRAdViewDelegate));

            [generator placeAdInView:view placementKey:@"placementKey" presentingViewController:presentingViewController delegate:delegate];
            spinner = (UIActivityIndicatorView *) [view.subviews lastObject];
        });

        it(@"stores the itself (the generator) as an associated object of the view", ^{
            objc_getAssociatedObject(view, STRAdGeneratorKey) should be_same_instance_as(generator);
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

        describe(@"follows up with its delegate", ^{
            describe(@"on success", ^{
                subjectAction(^{
                    [deferred resolveWithValue:ad];
                });

                context(@"when the delegate has a success callback", ^{
                    it(@"tells the delegate", ^{
                        delegate should have_received(@selector(adView:didFetchAdForPlacementKey:))
                        .with(view, @"placementKey");
                    });
                });

                context(@"when the delegate does not have a success callback", ^{
                    beforeEach(^{
                        delegate reject_method(@selector(adView:didFetchAdForPlacementKey:));
                    });

                    it(@"does not try to tell the delegate", ^{
                        delegate should_not have_received(@selector(adView:didFetchAdForPlacementKey:));
                    });
                });
            });

            describe(@"on failure", ^{
                subjectAction(^{
                    [deferred rejectWithError:nil];
                });

                context(@"when the delegate has an error callback", ^{
                    it(@"tells the delegate about the error", ^{
                        delegate should have_received(@selector(adView:didFailToFetchAdForPlacementKey:))
                        .with(view, @"placementKey");
                    });
                });

                context(@"when the delegate does not have an error callback", ^{
                    beforeEach(^{
                        delegate reject_method(@selector(adView:didFailToFetchAdForPlacementKey:));
                    });

                    it(@"does not try to call the delegate", ^{
                        delegate should_not have_received(@selector(adView:didFailToFetchAdForPlacementKey:));
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

            it(@"fires an impression kept beacon", ^{
                beaconService should have_received(@selector(fireImpressionForAd:adSize:)).with(ad, CGSizeMake(100, 100));
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

                    [[fakeRunLoop.sent_messages firstObject] getArgument:&timer atIndex:2];
                });

                subjectAction(^{
                    [timer fire];
                });

                context(@"when ad is >= 50% visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 0, 100, 100);
                    });

                    it(@"increments seconds visible", ^{
                        [timer.userInfo[@"secondsVisible"] floatValue] should be_greater_than(0.0);
                    });

                    it(@"should not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });

                    it(@"does not invalidates timer", ^{
                        timer.isValid should be_truthy;
                    });

                    context(@"and one second has passed", ^{
                        beforeEach(^{
                            timer.userInfo[@"secondsVisible"] = @1.0;
                        });

                        it(@"sends a beacon", ^{
                            beaconService should have_received(@selector(fireVisibleImpressionForAd:adSize:))
                            .with(ad, CGSizeMake(100, 100));
                        });

                        it(@"fires a third party beacon", ^{
                            beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//google.com?fakeParam=[timestamp]"]);
                        });

                        it(@"invalidates its timer", ^{
                            timer.isValid should be_falsy;
                        });
                    });

                    describe(@"when the ad goes off screen before 1 second has passed", ^{
                        beforeEach(^{
                            timer.userInfo[@"secondsVisible"] = @0.5;

                            view.frame = CGRectMake(1000, 1000, 100, 100);
                        });

                        it(@"resets the secondsVisible", ^{
                            timer.userInfo[@"secondsVisible"] should be_nil;
                        });
                    });
                });

                context(@"when the ad is 25% visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 360, 320, 480);
                    });

                    it(@"does not set secondsVisible", ^{
                        timer.userInfo[@"secondsVisible"] should be_nil;
                    });

                    it(@"should not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });

                    it(@"does not invalidates timer", ^{
                        timer.isValid should be_truthy;
                    });

                });

                context(@"when ad is 0% visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 481, 320, 500);
                    });

                    it(@"does not set secondsVisible", ^{
                        timer.userInfo[@"secondsVisible"] should be_nil;
                    });

                    it(@"should not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });

                    it(@"does not invalidates timer", ^{
                        timer.isValid should be_truthy;
                    });
                });

                context(@"after the ad is removed from its superview", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 481, 320, 500);
                        [view removeFromSuperview];
                    });

                    it(@"invalidates its timer", ^{
                        timer.isValid should be_falsy;
                    });

                    it(@"does not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
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

                it(@"fires off a youtube play beacon", ^{
                    beaconService should have_received(@selector(fireVideoPlayEvent:adSize:)).with(ad, CGSizeMake(100, 100));
                });

                it(@"fires off the third party beacons for click and for play", ^{
                    beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//click.com?fakeParam=[timestamp]"]);
                    beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//play.com?fakeParam=[timestamp]"]);
                });
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

        describe(@"when the view has already had an ad placed within it", ^{
            __block STRAdGenerator *secondGenerator;
            __block NSTimer *oldTimer;

            beforeEach(^{
                [deferred resolveWithValue:ad];

                [[fakeRunLoop.sent_messages firstObject] getArgument:&oldTimer atIndex:2];

                STRDeferred *newDeferred = [STRDeferred defer];
                
                STRAdService *newAdService = nice_fake_for([STRAdService class]);
                newAdService stub_method(@selector(fetchAdForPlacementKey:)).and_return(newDeferred.promise);

                secondGenerator = [[STRAdGenerator alloc] initWithAdService:newAdService beaconService:beaconService runLoop:fakeRunLoop injector:injector];
                [secondGenerator placeAdInView:view placementKey:@"key" presentingViewController:presentingViewController delegate:nil];

                [newDeferred resolveWithValue:ad];
            });

            it(@"should have cleaned up old tap gesture recognizers", ^{
                [view.gestureRecognizers count] should equal(1);
            });

            it(@"invalidates the old ad's timer", ^{
                oldTimer.isValid should be_falsy;

                __autoreleasing NSTimer *newTimer;
                [[fakeRunLoop.sent_messages lastObject] getArgument:&newTimer atIndex:2];

                newTimer should_not be_same_instance_as(oldTimer);
            });
        });

        context(@"when the ad is a clickout", ^{
            beforeEach(^{
                ad.action = @"clickout";

                view.frame = CGRectMake(0, 0, 100, 100);
                [deferred resolveWithValue:ad];
            });

            describe(@"the view is tapped on", ^{
                __block STRInteractiveAdViewController *interactiveAdController;

                beforeEach(^{
                    [(id<CedarDouble>)beaconService reset_sent_messages];
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

                it(@"fires off a clickout click beacon", ^{
                    beaconService should have_received(@selector(fireClickForAd:adSize:)).with(ad, CGSizeMake(100, 100));
                });

                it(@"fires off the third party beacons for click", ^{
                    beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//click.com?fakeParam=[timestamp]"]);
                });
            });
        });
    });

    describe(@"place an ad in a view without an ad description", ^{
        __block STRPlainAdView *view;
        __block STRDeferred *deferred;

        beforeEach(^{
            view = [STRPlainAdView new];
            deferred = [STRDeferred defer];

            adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(deferred.promise);
            [generator placeAdInView:view placementKey:@"placementKey" presentingViewController:nil delegate:nil];
        });

        it(@"does not try to include an ad description", ^{
            expect(^{
                [deferred resolveWithValue:ad];
            }).to_not(raise_exception);
        });
    });
});

SPEC_END
