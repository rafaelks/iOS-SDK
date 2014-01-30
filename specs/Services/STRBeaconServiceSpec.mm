#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRDateProvider.h"
#import "STRSession.h"
#import <AdSupport/AdSupport.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdvertisement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRBeaconServiceSpec)

describe(@"STRBeaconService", ^{
    __block STRBeaconService *service;
    __block STRRestClient *restClient;
    __block STRInjector *injector;
    __block STRAdvertisement *ad;

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

        ad = [[STRAdvertisement alloc] init];
        ad.creativeKey = @"creativeKey";
        ad.variantKey = @"variantKey";
        ad.placementKey = @"placementKey";
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

    describe(@"-fireImpressionForAd:adSize:", ^{
        beforeEach(^{
            [service fireImpressionForAd:ad adSize:CGSizeMake(200, 100)];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"ckey": @"creativeKey",
                                                                                         @"vkey": @"variantKey",
                                                                                         @"type": @"impression",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"pwidth": @"200",
                                                                                         @"pheight": @"100"});
        });

    });

    describe(@"-fireVisibleImpressionForAd:adSize:", ^{
        beforeEach(^{
            [service fireVisibleImpressionForAd:ad adSize:CGSizeMake(200, 100)];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"ckey": @"creativeKey",
                                                                                         @"vkey": @"variantKey",
                                                                                         @"type": @"visible",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"pwidth": @"200",
                                                                                         @"pheight": @"100"});
        });

    });

    describe(@"-fireYoutubePlayEvent:adSize:", ^{
        beforeEach(^{
            [service fireYoutubePlayEvent:ad adSize:CGSizeMake(200, 100)];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"ckey": @"creativeKey",
                                                                                         @"vkey": @"variantKey",
                                                                                         @"type": @"userEvent",
                                                                                         @"engagement": @"true",
                                                                                         @"userEvent": @"youtubePlay",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"pwidth": @"200",
                                                                                         @"pheight": @"100"});
        });

    });

    describe(@"-fireShareForAd:shareType:", ^{
        __block NSDictionary *shareOptions;
        __block NSString *shareType;

        subjectAction(^{
            shareOptions = @{@"pkey": @"placementKey",
                             @"ckey": @"creativeKey",
                             @"vkey": @"variantKey",
                             @"type": @"userEvent",
                             @"share": shareType,
                             @"engagement": @"true",
                             @"userEvent": @"share",
                             @"bwidth": @"200",
                             @"bheight": @"400",
                             @"umtime": @"10",
                             @"session": @"AAAA",
                             @"uid": @"fakeUUID"};
        });

        describe(@"when the share type is email", ^{
            beforeEach(^{
                [service fireShareForAd:ad shareType:UIActivityTypeMail];
                shareType = @"email";
            });

            it(@"sends a beacon to the tracking servers, with the correct share type", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(shareOptions);
            });
        });

        describe(@"when the share type is twitter", ^{
            beforeEach(^{
                [service fireShareForAd:ad shareType:UIActivityTypePostToTwitter];
                shareType = @"twitter";
            });

            it(@"sends a beacon to the tracking servers, with the correct share type", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(shareOptions);
            });
        });

        describe(@"when the share type is facebook", ^{
            beforeEach(^{
                [service fireShareForAd:ad shareType:UIActivityTypePostToFacebook];
                shareType = @"facebook";
            });

            it(@"sends a beacon to the tracking servers, with the correct share type", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(shareOptions);
            });
        });

        describe(@"when the share type is anything else", ^{
            beforeEach(^{
                [service fireShareForAd:ad shareType:UIActivityTypeMessage];
                shareType = UIActivityTypeMessage;
            });

            it(@"sends a beacon to the tracking servers, with the Apple's string as the share type", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(shareOptions);
            });
        });
    });


});

SPEC_END
