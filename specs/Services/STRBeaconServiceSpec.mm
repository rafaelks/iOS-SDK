#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRDateProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRBeaconServiceSpec)

describe(@"STRBeaconService", ^{
    __block STRBeaconService *service;
    __block STRRestClient *restClient;

    beforeEach(^{
        restClient = nice_fake_for([STRRestClient class]);
        STRDateProvider *dateProvider = nice_fake_for([STRDateProvider class]);
        dateProvider stub_method(@selector(millisecondsSince1970)).and_return(10L);
        service = [[STRBeaconService alloc] initWithRestClient:restClient dateProvider:dateProvider];
    });

    describe(@"fetching an ad", ^{
        beforeEach(^{
            restClient stub_method(@selector(sendBeaconWithParameters:));
            spy_on([UIScreen mainScreen]);
            [UIScreen mainScreen] stub_method(@selector(bounds)).and_return(CGRectMake(0, 0, 200, 400));

            [service fireImpressionRequestForPlacementKey:@"placementKey"];

        });

        it(@"makes a request to the ad server", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"type": @"impressionRequest",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10"});
        });
    });
});

SPEC_END
