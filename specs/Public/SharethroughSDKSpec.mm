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
            it(@"displays an Intel Ad", ^{
                UIView<STRAdView> *adView = [[STRFullAdView alloc] initWithFrame:CGRectZero];
                [[SharethroughSDK testSafeInstanceWithAdType:STRFakeAdTypeVine] placeAdInView:adView
                                                                                    placementKey:nil
                                                                        presentingViewController:nil
                                                                                        delegate:nil];

                adView.adTitle.text should equal(@"Meet A 15-year-old Cancer Researcher");
                adView.adDescription.text should equal(@"Meet Jack Andraka. Inventor, cancer researcher, 15 year old #ISEF winner. #findacure #lookinside");
                adView.adSponsoredBy.text should equal(@"Promoted by Intel");
            });
        });

        describe(@"when ad type is hosted", ^{
            it(@"displays an ad about almond milk", ^{
                UIView<STRAdView> *adView = [[STRFullAdView alloc] initWithFrame:CGRectZero];
                [[SharethroughSDK testSafeInstanceWithAdType:STRFakeAdTypeHostedVideo] placeAdInView:adView
                                                                                   placementKey:nil
                                                                       presentingViewController:nil
                                                                                       delegate:nil];

                adView.adTitle.text should equal(@"Avoid the morning MOO");
                adView.adDescription.text should equal(@"Avoid the taste of the dreaded MOO and make your morning taste better with Silk Almond Milk");
                adView.adSponsoredBy.text should equal(@"Promoted by Silk");

            });
        });
    });
});

SPEC_END
