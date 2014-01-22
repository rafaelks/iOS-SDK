#import "STRInteractiveAdViewController.h"
#import "STRAdvertisement.h"
#include "UIImage+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInteractiveAdViewControllerSpec)

describe(@"STRInteractiveAdViewController", ^{
    __block STRInteractiveAdViewController *controller;

    beforeEach(^{
        STRAdvertisement *ad = [STRAdvertisement new];
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
        controller = [[STRInteractiveAdViewController alloc] initWithAd:ad];
        controller.view should_not be_nil;
    });

    it(@"fills in the image preview with the ad thumbnail", ^{
        [controller.largePreview.image isEqualToByBytes:[UIImage imageNamed:@"fixture_image.png"]] should be_truthy;
    });

    describe(@"when the user taps the done button", ^{
        __block UIViewController *presentingViewController;

        beforeEach(^{
            presentingViewController = [UIViewController new];
            spy_on(presentingViewController);
            UIWindow *window = [UIWindow new];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];
            [presentingViewController presentViewController:controller animated:NO completion:nil];
            [controller doneButtonPressed:nil];
        });

        it(@"dismisses this view controller", ^{
            presentingViewController should have_received(@selector(dismissViewControllerAnimated:completion:));
        });
    });
});

SPEC_END
