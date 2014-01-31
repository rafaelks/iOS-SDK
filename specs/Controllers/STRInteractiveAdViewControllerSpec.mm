#import "STRInteractiveAdViewController.h"
#import "UIActivityViewController+Spec.h"
#include "UIBarButtonItem+Spec.h"
#include "UIImage+Spec.h"
#include "UIWebView+Spec.h"
#import "STRBeaconService.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdYouTube.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInteractiveAdViewControllerSpec)

describe(@"STRInteractiveAdViewController", ^{
    __block STRInteractiveAdViewController *controller;
    __block STRAdvertisement *ad;
    __block UIDevice *device;
    __block STRBeaconService *beaconService;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];
        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        ad = [STRAdYouTube new];
        device = [UIDevice currentDevice];
        ad.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=BWAK0J8Uhzk"];
        ad.title = @"Superad";
        ad.shareURL = [NSURL URLWithString:@"http://bit.ly/23kljr"];

        controller = [[STRInteractiveAdViewController alloc] initWithAd:ad device:device beaconService:beaconService];
        UIWindow *window = [UIWindow new];
        [window addSubview:controller.view];
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
            ((NSString *)[controller.webView.executedJavaScripts firstObject]) should contain(@"height = 504");
        });
    });

    describe(@"when subviews are re-layed out (e.g. returning from the full screen viewer where they have rotated)", ^{
        it(@"resizes the YouTube embed", ^{
            spy_on(controller.contentView);
            controller.contentView stub_method(@selector(transform)).and_return(CGAffineTransformMakeRotation(M_PI_2));
            [controller viewDidLayoutSubviews];

            ((NSString *)[controller.webView.executedJavaScripts lastObject]) should contain(@"width = 504");
            ((NSString *)[controller.webView.executedJavaScripts lastObject]) should contain(@"height = 320");
        });
    });

    describe(@"when the user taps the done button", ^{
        __block id<STRInteractiveAdViewControllerDelegate> delegate;

        beforeEach(^{
            delegate = nice_fake_for(@protocol(STRInteractiveAdViewControllerDelegate));
            controller.delegate = delegate;
            [controller.doneButton tap];
        });

        it(@"notifies its delegate", ^{
            delegate should have_received(@selector(closedInteractiveAdView:)).with(controller);
        });
    });

    describe(@"when the user taps the share button on an iPhone", ^{
        __block UIActivityViewController *activityController;
        beforeEach(^{
            spy_on(device);
            device stub_method(@selector(userInterfaceIdiom)).and_return(UIUserInterfaceIdiomPhone);
            [controller.shareButton tap];
            activityController = (UIActivityViewController *) controller.presentedViewController;
        });

        it(@"presents the UIActivityViewController", ^{

            activityController should be_instance_of([UIActivityViewController class]);
            activityController.activityItems should equal(@[ad.title, @"http://bit.ly/23kljr"]);
        });

        describe(@"when the user selects a share option", ^{
            beforeEach(^{
                activityController.completionHandler(UIActivityTypeMail, YES);
            });

            it(@"fires a sharing beacon", ^{
                beaconService should have_received(@selector(fireShareForAd:shareType:)).with(ad, UIActivityTypeMail);
            });
        });

        describe(@"when the user does not select a share option", ^{
            beforeEach(^{
                activityController.completionHandler(nil, NO);
            });

            it(@"does not fire a share beacon", ^{
                beaconService should_not have_received(@selector(fireShareForAd:shareType:));
            });
        });
    });

    describe(@"when the user taps the share button on an iPad", ^{
        beforeEach(^{
            spy_on(device);
            device stub_method(@selector(userInterfaceIdiom)).and_return(UIUserInterfaceIdiomPad);
            [controller.shareButton tap];
        });

        it(@"shows the UIActivityViewController in a popover", ^{
            UIActivityViewController *activityController = (UIActivityViewController *) controller.sharePopoverController.contentViewController;
            activityController should be_instance_of([UIActivityViewController class]);
            activityController.activityItems should equal(@[ad.title, @"http://bit.ly/23kljr"]);

            controller.sharePopoverController.isPopoverVisible should be_truthy;
        });

        it(@"closes the popover when user taps done", ^{
            [controller.doneButton tap];
            controller.sharePopoverController.isPopoverVisible should be_falsy;
        });

        it(@"keeps the same popover if the user taps the share button again", ^{
            UIPopoverController *existingPopoverController = controller.sharePopoverController;
            [controller.sharePopoverController dismissPopoverAnimated:NO];
            [controller.shareButton tap];
            controller.sharePopoverController should be_same_instance_as(existingPopoverController);
            controller.sharePopoverController.isPopoverVisible should be_truthy;
        });
    });
});

SPEC_END
