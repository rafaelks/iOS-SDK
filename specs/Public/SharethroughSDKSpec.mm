#import "SharethroughSDK.h"
#import "STRInjector.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SharethroughSDKSpec)

describe(@"SharethroughSDK", ^{
    describe(@"getting the shared instance", ^{
        it(@"returns the same instance each time", ^{
            [SharethroughSDK sharedInstance] should be_same_instance_as([SharethroughSDK sharedInstance]);
        });
    });

    describe(@"getting the test safe instance", ^{
        it(@"always returns a new instance", ^{
            [SharethroughSDK testSafeInstance] should_not be_same_instance_as([SharethroughSDK testSafeInstance]);
        });
    });
});

SPEC_END
