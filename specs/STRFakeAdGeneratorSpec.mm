#import "STRFakeAdGenerator.h"
#import <objc/runtime.h>
#import "STRFullAdView.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRFakeAdGeneratorSpec)

describe(@"STRFakeAdGenerator", ^{
    __block STRFakeAdGenerator *generator;

    beforeEach(^{
        generator = [STRFakeAdGenerator new];
    });

    it(@"raises exception on default initializer", ^{
        __block id dummyGenerator;
        expect(^{
            dummyGenerator = [[STRFakeAdGenerator alloc] initWithAdService:nil
                                                             beaconService:nil
                                                                   runLoop:nil
                                                                  injector:nil];
        }).to(raise_exception);
    });
    
    describe(@"-placeAdInView:placementKey:presentingViewController:delegate:", ^{
        __block STRFullAdView *view;
        __block UIViewController *presentingViewController;

        beforeEach(^{
            view = [STRFullAdView new];
            [UIGestureRecognizer whitelistClassForGestureSnooping:[STRFakeAdGenerator class]];
            presentingViewController = [UIViewController new];

            [generator placeAdInView:view
                        placementKey:nil
            presentingViewController:presentingViewController
                            delegate:nil];
        });

        it(@"stores the itself (the generator) as an associated object of the view", ^{
            objc_getAssociatedObject(view, STRAdGeneratorKey) should be_same_instance_as(generator);
        });

        it(@"sets the content of the view", ^{
            view.adTitle.text should equal(@"Generic Ad Title");
            view.adSponsoredBy.text should equal(@"Promoted by Sharethrough");
            view.adThumbnail.image should be_nil;
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
                interactiveAdController.delegate should be_same_instance_as(generator);
            });

            it(@"dismisses the interactive ad controller when told", ^{
                [interactiveAdController.delegate closedInteractiveAdView:interactiveAdController];

                presentingViewController.presentedViewController should be_nil;
            });
        });

    });
});

SPEC_END
