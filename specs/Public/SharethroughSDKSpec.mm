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

    describe(@"+sharedTestSafeInstanceWithAdType:", ^{
        it(@"returns the same instance each time", ^{
            [SharethroughSDK sharedTestSafeInstanceWithAdType:STRFakeAdTypeYoutube] should be_same_instance_as([SharethroughSDK sharedTestSafeInstanceWithAdType:STRFakeAdTypeYoutube]);
        });

        describe(@"when ad type is youtube", ^{
            it(@"displays an ad about Pepsi", ^{
                UIView<STRAdView> *adView = [[STRFullAdView alloc] initWithFrame:CGRectZero];
                [[SharethroughSDK sharedTestSafeInstanceWithAdType:STRFakeAdTypeYoutube] placeAdInView:adView
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
                [[SharethroughSDK sharedTestSafeInstanceWithAdType:STRFakeAdTypeVine] placeAdInView:adView
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
                [[SharethroughSDK sharedTestSafeInstanceWithAdType:STRFakeAdTypeHostedVideo] placeAdInView:adView
                                                                                   placementKey:nil
                                                                       presentingViewController:nil
                                                                                       delegate:nil];

                adView.adTitle.text should equal(@"Avoid the morning MOO");
                adView.adDescription.text should equal(@"Avoid the taste of the dreaded MOO and make your morning taste better with Silk Almond Milk");
                adView.adSponsoredBy.text should equal(@"Promoted by Silk");

            });
        });

        describe(@"when the ad type is clickout", ^{
            it(@"displays an ad about 22 gameday gifs ", ^{
                UIView<STRAdView> *adView = [[STRFullAdView alloc] initWithFrame:CGRectZero];
                [[SharethroughSDK sharedTestSafeInstanceWithAdType:STRFakeAdTypeClickout] placeAdInView:adView
                                                                                     placementKey:nil
                                                                         presentingViewController:nil
                                                                                         delegate:nil];

                adView.adTitle.text should equal(@"22 Game Day Gifs That Will Pump You Up For Anything");
                adView.adDescription.text should equal(@"Get in the zone and check out these GIFs before your next big challenge to ensure victory. Then taste the winning kick of McDonald's® Mighty Wings® , now available nationwide.");
                adView.adSponsoredBy.text should equal(@"Promoted by McDonald's");
            });
        });
    });
});

SPEC_END
