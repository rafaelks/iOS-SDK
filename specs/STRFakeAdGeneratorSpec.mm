#import "STRFakeAdGenerator.h"
#import <objc/runtime.h>
#import "STRFullAdView.h"
#import "STRInteractiveAdViewController.h"
#import "STRAdPlacement.h"
#include "UIGestureRecognizer+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRFakeAdGeneratorSpec)

describe(@"STRFakeAdGenerator", ^{
    __block STRFakeAdGenerator *generator;

    beforeEach(^{
        generator = [STRFakeAdGenerator new];
    });
    
    describe(@"-placeAdInView:placementKey:presentingViewController:delegate:", ^{
        __block STRFullAdView *view;
        __block UIViewController *presentingViewController;

        beforeEach(^{
            view = [STRFullAdView new];
//            [UIGestureRecognizer whitelistClassForGestureSnooping:[STRFakeAdGenerator class]];
            presentingViewController = [UIViewController new];
            STRAdPlacement *placement = [[STRAdPlacement alloc] initWithAdView:view
                                                                  PlacementKey:@"fakePlacementKey"
                                                      presentingViewController:presentingViewController
                                                                      delegate:nil
                                                                       adIndex:0
                                                                  isDirectSold:NO
                                                                       DFPPath:nil
                                                                   DFPDeferred:nil
                                                              customProperties:nil];

            [generator placeAdInPlacement:placement];
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
            });
        });

    });
});

SPEC_END
