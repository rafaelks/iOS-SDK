#import "SharethroughSDK.h"
#import "STRInjector.h"
#import "STRFullAdView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SharethroughSDKSpec)

describe(@"SharethroughSDK", ^{
    describe(@"+sharedInstance", ^{
        it(@"returns the same instance each time", ^{
            [SharethroughSDK sharedInstance] should be_same_instance_as([SharethroughSDK sharedInstance]);
        });
    });

    describe(@"+testSafeInstanceWithAdType:", ^{
        it(@"always returns a new instance", ^{
            [SharethroughSDK testSafeInstanceWithAdType:STRFakeAdTypeYoutube] should_not be_same_instance_as([SharethroughSDK testSafeInstanceWithAdType:STRFakeAdTypeYoutube]);
        });

        describe(@"when ad type is youtube", ^{

            it(@"displays an ad about Pepsi", ^{
                UIView<STRAdView> *adView = [[STRFullAdView alloc] initWithFrame:CGRectZero];
                [[SharethroughSDK testSafeInstanceWithAdType:STRFakeAdTypeYoutube] placeAdInView:adView
                                                                                    placementKey:nil
                                                                        presentingViewController:nil
                                                                                        delegate:nil];

                adView.adTitle.text should equal(@"Go Sip for Sip with Josh Duhamel");
                adView.adDescription.text should equal(@"Grab a Diet Pepsi and share a delicious moment with Josh Duhamel");
                adView.adSponsoredBy.text should equal(@"Promoted by Pepsi");
            });

        });
        describe(@"when ad type is vine", ^{

        });
    });
});

SPEC_END
