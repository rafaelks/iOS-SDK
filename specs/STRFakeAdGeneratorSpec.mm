#import "STRFakeAdGenerator.h"
#import <objc/runtime.h>
#import "STRFullAdView.h"

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
        beforeEach(^{
            view = [STRFullAdView new];

            [generator placeAdInView:view placementKey:nil presentingViewController:nil delegate:nil];
        });

        it(@"stores the itself (the generator) as an associated object of the view", ^{
            objc_getAssociatedObject(view, STRAdGeneratorKey) should be_same_instance_as(generator);
        });

        it(@"sets the content of the view", ^{
            view.adTitle.text should equal(@"Generic Ad Title");
            view.adSponsoredBy.text should equal(@"Promoted by Sharethrough");
            view.adThumbnail.image should be_nil;
        });
    });
});

SPEC_END
