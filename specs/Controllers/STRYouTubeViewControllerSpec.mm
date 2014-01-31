#import "STRYouTubeViewController.h"
#import "STRAdYouTube.h"
#include "UIWebView+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRYouTubeViewControllerSpec)

describe(@"STRYouTubeViewController", ^{
    __block STRYouTubeViewController *controller;
    __block STRAdYouTube *ad;

    beforeEach(^{
        ad = [STRAdYouTube new];
        ad.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=BWAK0J8Uhzk"];
        ad.title = @"Superad";
        ad.shareURL = [NSURL URLWithString:@"http://bit.ly/23kljr"];

        controller = [[STRYouTubeViewController alloc] initWithAd:ad];
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
            ((NSString *)[controller.webView.executedJavaScripts firstObject]) should contain(@"height = 568");
        });
    });

    describe(@"when subviews are re-layed out (e.g. returning from the full screen viewer where they have rotated)", ^{
        it(@"resizes the YouTube embed", ^{
            spy_on(controller.view);
            controller.view stub_method(@selector(transform)).and_return(CGAffineTransformMakeRotation(M_PI_2));
            [controller viewDidLayoutSubviews];

            ((NSString *)[controller.webView.executedJavaScripts lastObject]) should contain(@"width = 568");
            ((NSString *)[controller.webView.executedJavaScripts lastObject]) should contain(@"height = 320");
        });
    });
});

SPEC_END
