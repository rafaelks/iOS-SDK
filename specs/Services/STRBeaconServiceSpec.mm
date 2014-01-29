#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRDateProvider.h"
#import "STRSession.h"
#import <AdSupport/AdSupport.h>
#import "STRInjector.h"
#import "STRAppModule.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRBeaconServiceSpec)

describe(@"STRBeaconService", ^{
    __block STRBeaconService *service;
    __block STRRestClient *restClient;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule moduleWithStaging:NO]];

        restClient = nice_fake_for([STRRestClient class]);
        [injector bind:[STRRestClient class] toInstance:restClient];

        STRDateProvider *dateProvider = nice_fake_for([STRDateProvider class]);
        dateProvider stub_method(@selector(millisecondsSince1970)).and_return(10LL);
        [injector bind:[STRDateProvider class] toInstance:dateProvider];

        spy_on([UIScreen mainScreen]);
        [UIScreen mainScreen] stub_method(@selector(bounds)).and_return(CGRectMake(0, 0, 200, 400));

        ASIdentifierManager *fakeManager = nice_fake_for([ASIdentifierManager class]);
        spy_on([ASIdentifierManager class]);
        [injector bind:[ASIdentifierManager class] toInstance:fakeManager];

        NSUUID *fakeId = nice_fake_for([NSUUID class]);
        fakeId stub_method(@selector(UUIDString)).and_return(@"fakeUUID");
        fakeManager stub_method(@selector(advertisingIdentifier)).and_return(fakeId);

        spy_on([STRSession class]);
        [STRSession class] stub_method(@selector(sessionToken)).and_return(@"AAAA");

        restClient stub_method(@selector(sendBeaconWithParameters:));
        service = [injector getInstance:[STRBeaconService class]];
    });

    describe(@"-fireImpressionRequestForPlacementKey:", ^{
        beforeEach(^{
            [service fireImpressionRequestForPlacementKey:@"placementKey"];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"type": @"impressionRequest",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID"});
        });
    });

    describe(@"-fireVisibleImpressionForPlacementKey:", ^{
        beforeEach(^{
            [service fireVisibleImpressionForPlacementKey:@"placementKey"];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                        @"type": @"visible",
                                                                                        @"bwidth": @"200",
                                                                                        @"bheight": @"400",
                                                                                        @"umtime": @"10",
                                                                                        @"session": @"AAAA",
                                                                                        @"uid": @"fakeUUID"});
        });

    });

});

SPEC_END
