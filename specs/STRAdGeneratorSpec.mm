#import "STRAdGenerator.h"
#import "STRAdViewFixture.h"
#import "STRRestClient.h"
#import "STRDeferred.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;
    __block STRRestClient *restClient;

    beforeEach(^{
        restClient = nice_fake_for([STRRestClient class]);
        generator = [[STRAdGenerator alloc] initWithPriceKey:@"priceKey" restClient:restClient];
    });

    describe(@"placing an ad in the view", ^{
        __block STRAdViewFixture *view;
        __block STRDeferred *deferred;
        __block UIActivityIndicatorView *spinner;

        beforeEach(^{
            view = [STRAdViewFixture new];
            deferred = [STRDeferred defer];
            restClient stub_method(@selector(getWithParameters:)).and_return(deferred.promise);
            [generator placeAdInView:view placementKey:@"placementKey"];
            spinner = (UIActivityIndicatorView *) [view.subviews lastObject];
        });

        it(@"shows a spinner while the ad is being fetched", ^{
            spinner should be_instance_of([UIActivityIndicatorView class]);
        });

        it(@"makes a network request", ^{
            restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey"});
        });

        describe(@"when the ad has fetched successfully", ^{
            beforeEach(^{
                [deferred resolveWithValue:@{
                                                @"description": @"Dogs this smart deserve a home.",
                                                @"thumbnail_url": @"http:\\/\\/i1.ytimg.com\\/vi\\/BWAK0J8Uhzk\\/hqdefault.jpg",
                                                @"title": @"Meet Porter. He's a Dog.",
                                                @"advertiser": @"Brand X",
                                             }];
            });

            it(@"removes the spinner", ^{
                spinner.superview should be_nil;
            });

            it(@"fills out the ads' the title, description, and sponsored by", ^{
                view.adTitle.text should equal(@"Meet Porter. He's a Dog.");
                view.adDescription.text should equal(@"Dogs this smart deserve a home.");
                view.adSponsoredBy.text should equal(@"Promoted by Brand X");
            });

            it(@"adds a placeholder image", ^{
                UIImage *expectedImage = [UIImage imageNamed:@"STRResources.bundle/images/fixture_image.png"];
                NSData *expectedImageData = UIImagePNGRepresentation(expectedImage);
                UIImagePNGRepresentation(view.adThumbnail.image) should equal(expectedImageData);
                view.adThumbnail.contentMode should equal(UIViewContentModeScaleAspectFill);
            });
        });

        describe(@"when the ad has fetched successfully", ^{
            beforeEach(^{
                [deferred rejectWithError:[NSError errorWithDomain:@"Error!" code:101 userInfo:nil]];
            });

            it(@"removes the spinner", ^{
                spinner.superview should be_nil;
            });
        });
    });
});

SPEC_END
