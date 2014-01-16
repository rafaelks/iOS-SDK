#import "SharethroughSDK.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SharethroughSDKSpec)

describe(@"SharethroughSDK", ^{
    __block SharethroughSDK *sdk;

    beforeEach(^{
        sdk = [SharethroughSDK new];
    });

    it(@"can greet", ^{
        UILabel *helloLabel = (UILabel *)[sdk greetHello];
        helloLabel.text should equal(@"Hello from SDK!");
    });
});

SPEC_END
