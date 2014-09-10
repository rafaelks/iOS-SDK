#import "STRSpecModule.h"
#import <objc/runtime.h>

#import "STRDFPManager.h"
#import "STRDFPAppModule.h"
#import "STRAdGenerator.h"
#import "STRAdPlacement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(DFPManagerSpec)

describe(@"DFPManager", ^{
    __block STRInjector *injector;
    __block STRDFPManager *dfpManager;
    __block STRAdGenerator *generator;
    __block STRAdPlacement *adPlacement;
    __block id<STRAdViewDelegate> delegate;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRDFPAppModule new]];
        dfpManager = [STRDFPManager sharedInstance];
        dfpManager.injector = injector;

        generator = nice_fake_for([STRAdGenerator class]);
        [injector bind:[STRAdGenerator class] toInstance:generator];

        delegate = nice_fake_for(@protocol(STRAdViewDelegate));

        adPlacement = [[STRAdPlacement alloc] initWithPlacementKey:@"placementKey"
                                          presentingViewController:nil
                                                          delegate:delegate];
    });

    context(@"-renderCreative:inPlacement", ^{
        beforeEach(^{
            [dfpManager cacheAdPlacement:adPlacement];
        });

        describe(@"when the placement deferred is not set", ^{
            beforeEach(^{
                [dfpManager renderCreative:@"creativeKey" inPlacement:@"placementKey"];
            });

            it(@"calls placeCreative:inPlacement in the generator", ^{
                generator should have_received(@selector(placeCreative:inPlacement:));
            });
        });

        describe(@"when the placement deferred is set", ^{
            beforeEach(^{
                STRDeferred *deferred = [STRDeferred defer];
                [dfpManager renderCreative:@"creativeKey" inPlacement:@"placementKey"];
            });

            it(@"calls placeCreative:inPlacement in the generator", ^{
                generator should have_received(@selector(placeCreative:inPlacement:));
            });
        });
    });
});

SPEC_END
