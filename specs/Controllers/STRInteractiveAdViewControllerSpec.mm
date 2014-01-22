#import "STRInteractiveAdViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInteractiveAdViewControllerSpec)

describe(@"STRInteractiveAdViewController", ^{
    __block STRInteractiveAdViewController *controller;

    beforeEach(^{
        controller = [STRInteractiveAdViewController new];
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
