#import "STRClickoutViewController.h"
#import "STRAdvertisement.h"
#import "STRAdFixtures.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRClickoutViewControllerSpec)

describe(@"STRClickoutViewController", ^{
    __block STRClickoutViewController *controller;
    __block STRAdvertisement *advertisement;

    beforeEach(^{
        advertisement = (id)[STRAdFixtures clickoutAd];

        controller = [[STRClickoutViewController alloc] initWithAd:advertisement];
        controller.view should_not be_nil;
    });

    it(@"loads the advertisement url in the webview", ^{
        controller.webview.request.URL should equal(advertisement.mediaURL);
    });
});

SPEC_END
