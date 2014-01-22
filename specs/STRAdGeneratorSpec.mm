#import "STRAdGenerator.h"
#import "STRAdViewFixture.h"
#import "STRAdService.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;
    __block STRAdService *adService;

    beforeEach(^{
        [UIGestureRecognizer whitelistClassForGestureSnooping:[STRAdGenerator class]];
        adService = nice_fake_for([STRAdService class]);
        generator = [[STRAdGenerator alloc] initWithPriceKey:@"priceKey" adService:adService];
    });

    describe(@"placing an ad in the view", ^{
        __block STRAdViewFixture *view;
        __block STRDeferred *deferred;
        __block UIActivityIndicatorView *spinner;
        __block UIViewController *presentingViewController;

        beforeEach(^{
            view = [STRAdViewFixture new];
            deferred = [STRDeferred defer];

            presentingViewController = [UIViewController new];
            UIWindow *window = [UIWindow new];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];

            adService stub_method(@selector(fetchAdForPlacementKey:)).and_return(deferred.promise);
            [generator placeAdInView:view placementKey:@"placementKey" presentingViewController:presentingViewController];
            spinner = (UIActivityIndicatorView *) [view.subviews lastObject];
        });

        it(@"shows a spinner while the ad is being fetched", ^{
            spinner should be_instance_of([UIActivityIndicatorView class]);
        });

        it(@"makes a network request", ^{
            adService should have_received(@selector(fetchAdForPlacementKey:)).with(@"placementKey");
        });

        describe(@"when the ad has fetched successfully", ^{
            beforeEach(^{
                STRAdvertisement *ad = [STRAdvertisement new];
                ad.adDescription = @"Dogs this smart deserve a home.";
                ad.title = @"Meet Porter. He's a Dog.";
                ad.advertiser = @"Brand X";
                ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];

                [deferred resolveWithValue:ad];
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
                UIImage *expectedImage = [UIImage imageNamed:@"fixture_image.png"];
                NSData *expectedImageData = UIImagePNGRepresentation(expectedImage);
                UIImagePNGRepresentation(view.adThumbnail.image) should equal(expectedImageData);
                view.adThumbnail.contentMode should equal(UIViewContentModeScaleAspectFill);
            });

            it(@"adds a gesture recognizer for taps", ^{
                [view.gestureRecognizers count] should equal(1);
                [view.gestureRecognizers lastObject] should be_instance_of([UITapGestureRecognizer class]);
            });

            it(@"presents the STRInteractiveAdViewController when the ad is tapped on", ^{
                [[view.gestureRecognizers lastObject] recognize];
                presentingViewController.presentedViewController should be_instance_of([STRInteractiveAdViewController class]);
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
