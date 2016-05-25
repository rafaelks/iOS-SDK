#import "STRAdPlacement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdPlacementSpec)

describe(@"STRAdPlacement", ^{
    describe(@"- initWithAdView:PlacementKey:presentingViewController:delegate:", ^{
        it(@"throws an exception if placementKey is nil", ^{
            expect(^{
                STRAdPlacement *placement __unused = [[STRAdPlacement alloc] initWithAdView:nil
                                                                      PlacementKey:nil
                                                          presentingViewController:nil
                                                                          delegate:nil
                                                                           adIndex:0
                                                                           customProperties:nil];
            }).to(raise_exception);
        });

        it(@"throws an exception if placementKey is too short", ^{
            expect(^{
                STRAdPlacement *placement __unused = [[STRAdPlacement alloc] initWithAdView:nil
                                                                      PlacementKey:@"1234567"
                                                          presentingViewController:nil
                                                                          delegate:nil
                                                                           adIndex:0
                                                                           customProperties:nil];
            }).to(raise_exception);
        });
    });
});

SPEC_END