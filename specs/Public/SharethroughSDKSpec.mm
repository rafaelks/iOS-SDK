#import "SharethroughSDK.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SharethroughSDKSpec)

describe(@"SharethroughSDK", ^{
    describe(@"getting the shared instance", ^{
        it(@"returns the same instance each time", ^{
            [SharethroughSDK sharedInstance] should be_same_instance_as([SharethroughSDK sharedInstance]);
        });
    });

    describe(@"configuring settings", ^{
        it(@"maintains settings", ^{
            SharethroughSDK *sdk = [SharethroughSDK sharedInstance];
            [sdk configureWithStaging:YES];
            sdk.isStaging should equal(YES);
        });
    });
});

SPEC_END
