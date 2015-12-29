#import "SharethroughSDK+DFP.h"
#import "STRInjector.h"
#import "STRDFPAdGenerator.h"
#import "STRDFPAppModule.h"
#import "STRAdPlacement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SharethroughSDKDFPSpec)

describe(@"SharethroughSDK+DFP", ^{
    describe(@"+sharedInstance", ^{
        it(@"returns the same instance each time", ^{
            [SharethroughSDKDFP sharedInstance] should be_same_instance_as([SharethroughSDKDFP sharedInstance]);
        });
    });

    describe(@"-prefetchAdForPlacementKey:delegate", ^{
        __block STRInjector *injector;
        __block STRDFPAdGenerator *fakeGenerator;
        __block id<STRAdViewDelegate> fakeDelegate;
        __block SharethroughSDKDFP *dfpSDK;

        beforeEach(^{
            injector = [STRInjector injectorForModule:[STRDFPAppModule new]];

            fakeGenerator = nice_fake_for([STRDFPAdGenerator class]);
            [injector bind:[STRDFPAdGenerator class] toInstance:fakeGenerator];

            spy_on([STRInjector class]);
            [STRInjector class] stub_method(@selector(injectorForModule:)).and_return(injector);

            dfpSDK = [[SharethroughSDKDFP alloc] init];

            fakeDelegate = fake_for(@protocol(STRAdViewDelegate));
            fakeDelegate stub_method(@selector(didPrefetchAdvertisement:));
            fakeDelegate stub_method(@selector(didFailToPrefetchForPlacementKey:));

        });

        it(@"informs the delegate when an ad is successfully fetched", ^{
            fakeGenerator stub_method(@selector(placeAdInPlacement:)).and_do(^(NSInvocation *invocation) {
                STRAdPlacement *adPlacement = (STRAdPlacement *)invocation.arguments[0];
                [adPlacement.DFPDeferred resolveWithValue:nil];
            });

            [dfpSDK prefetchAdForPlacementKey:@"fakePlacementKey" delegate:fakeDelegate];
            fakeDelegate should have_received(@selector(didPrefetchAdvertisement:));
        });

        it(@"informs the delegate when an ad is unsuccessfully fetched", ^{
            fakeGenerator stub_method(@selector(placeAdInPlacement:)).and_do(^(NSInvocation *invocation) {
                STRAdPlacement *adPlacement = (STRAdPlacement *)invocation.arguments[0];
                [adPlacement.DFPDeferred rejectWithError:nil];
            });

            [dfpSDK prefetchAdForPlacementKey:@"fakePlacementKey" delegate:fakeDelegate];
            fakeDelegate should have_received(@selector(didFailToPrefetchForPlacementKey:));
        });
    });
});

SPEC_END
