#import "STRInteractiveAdViewController.h"
#import "STRAdvertisement.h"
#include "UIImage+Spec.h"
#include "UIWebView+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInteractiveAdViewControllerSpec)

describe(@"STRInteractiveAdViewController", ^{
    __block STRInteractiveAdViewController *controller;
    __block STRAdvertisement *ad;

    beforeEach(^{
        ad = [STRAdvertisement new];
        ad.mediaUrl = [NSURL URLWithString:@"http://www.youtube.com/watch?v=BWAK0J8Uhzk"];

        controller = [[STRInteractiveAdViewController alloc] initWithAd:ad];
        controller.view should_not be_nil;
        [controller.view layoutIfNeeded];
    });

    it(@"shows a spinner while the webview is loading", ^{
        controller.spinner.superview should_not be_nil;
    });

    it(@"loads the web view with YouTube embed html", ^{
        controller.webView.loadedHTMLString should contain(@"div id='player'");
        controller.webView.loadedHTMLString should contain(@"videoId: 'BWAK0J8Uhzk'");
    });

    describe(@"when the web view has finished loading", ^{
        beforeEach(^{
            [controller.webView.delegate webViewDidFinishLoad:controller.webView];
        });

        it(@"hides the spinner while the webview is loading", ^{
            controller.spinner.superview should be_nil;
        });

        it(@"sizes the YouTube embed to be as large as possible", ^{
            ((NSString *)[controller.webView.executedJavaScripts firstObject]) should contain(@"width = 320");
            ((NSString *)[controller.webView.executedJavaScripts firstObject]) should contain(@"height = 516");
        });
    });

    describe(@"when subviews are re-layed out (e.g. returning from the full screen viewer where they have rotated)", ^{
        it(@"resizes the YouTube embed", ^{
            spy_on(controller.contentView);
            controller.contentView stub_method(@selector(transform)).and_return(CGAffineTransformMakeRotation(M_PI_2));
            [controller viewDidLayoutSubviews];

            ((NSString *)[controller.webView.executedJavaScripts lastObject]) should contain(@"width = 516");
            ((NSString *)[controller.webView.executedJavaScripts lastObject]) should contain(@"height = 320");
        });
    });

    describe(@"when the user taps the done button", ^{
        __block id<STRInteractiveAdViewControllerDelegate> delegate;

        beforeEach(^{
            delegate = nice_fake_for(@protocol(STRInteractiveAdViewControllerDelegate));
            controller.delegate = delegate;
            [controller doneButtonPressed:nil];
        });

        it(@"notifies its delegate", ^{
            delegate should have_received(@selector(closedInteractiveAdView:)).with(controller);
        });
    });
});

SPEC_END
