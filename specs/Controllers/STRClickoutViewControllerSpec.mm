#import "STRClickoutViewController.h"
#import "STRAdvertisement.h"
#import "STRAdFixtures.h"
#import "STRBeaconService.h"

#import "UIWebView+Spec.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRClickoutViewControllerSpec)

describe(@"STRClickoutViewController", ^{
    __block STRClickoutViewController *controller;
    __block STRAdvertisement *advertisement;
    __block STRBeaconService *beaconService;

    describe(@"when the ad is a clickout", ^{

        beforeEach(^{
            advertisement = (id)[STRAdFixtures clickoutAd];

            beaconService = nice_fake_for([STRBeaconService class]);

            controller = [[STRClickoutViewController alloc] initWithAd:advertisement beaconService:beaconService];
            controller.view should_not be_nil;
        });

        it(@"loads the advertisement url in the webview", ^{
            controller.webview.request.URL should equal(advertisement.mediaURL);
        });
    });

    describe(@"when the ad is an article", ^{
        beforeEach(^{
            advertisement = (id)[STRAdFixtures articleAd];

            beaconService = nice_fake_for([STRBeaconService class]);

            controller = [[STRClickoutViewController alloc] initWithAd:advertisement beaconService:beaconService];
            controller.view should_not be_nil;
        });

        it(@"loads the advertisement url in the webview", ^{
            controller.webview.request.URL should equal(advertisement.mediaURL);
        });

        it(@"fires an article view beacon", ^{
            beaconService should have_received(@selector(fireArticleViewForAd:)).with(advertisement);
        });

        it(@"does not fire an articleViewDuration beacon yet", ^{
            beaconService should_not have_received(@selector(fireArticleDurationForAd:withDuration:));
        });

        describe(@"viewWillDisappear", ^{
            it(@"fires an articleviewDuration beacon ", ^{
                [controller viewWillDisappear:YES];
                beaconService should have_received(@selector(fireArticleDurationForAd:withDuration:));
            });
        });

        describe(@"UIWebViewDelegate", ^{
            beforeEach(^{
                [controller.webview finishLoad];
            });

            it(@"fires an articleViewDuration beacon if the domain is not platform-cdn.sharethrough.com", ^{
                NSURL *url = [NSURL URLWithString:@"https://www.google.com"];
                [controller.webview loadRequest:[NSURLRequest requestWithURL:url]];
                beaconService should have_received(@selector(fireArticleDurationForAd:withDuration:));
            });

            it(@"does not fire multiple article view beacons", ^{
                NSURL *url = [NSURL URLWithString:@"https://www.google.com"];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                [controller.webview loadRequest:request];
                beaconService should have_received(@selector(fireArticleDurationForAd:withDuration:));

                [controller.webview finishLoad];
                [(id<CedarDouble>)beaconService reset_sent_messages];
                [controller.webview loadRequest:request];
                beaconService should_not have_received(@selector(fireArticleDurationForAd:withDuration:));
            });

            it(@"does not fire an articleViewDuration beacon if the domain is platform-cdn.sharethrough.com", ^{
                NSURL *url = [NSURL URLWithString:@"https://platform-cdn.sharethrough.com/blah"];
                [controller.webview loadRequest:[NSURLRequest requestWithURL:url]];
                beaconService should_not have_received(@selector(fireArticleDurationForAd:withDuration:));
            });
        });
    });
});

SPEC_END
