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
        injector = [STRInjector injectorForModule:[STRAppModule new]];

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
        fakeManager stub_method(@selector(isAdvertisingTrackingEnabled)).and_return(YES);

        NSUUID *fakeId = nice_fake_for([NSUUID class]);
        fakeId stub_method(@selector(UUIDString)).and_return(@"fakeUUID");
        fakeManager stub_method(@selector(advertisingIdentifier)).and_return(fakeId);

        spy_on([STRSession class]);
        [STRSession class] stub_method(@selector(sessionToken)).and_return(@"AAAA");

        restClient stub_method(@selector(sendBeaconWithParameters:));
        restClient stub_method(@selector(getUserAgent)).and_return(@"User Agent");
        service = [injector getInstance:[STRBeaconService class]];

        ad = [[STRAdvertisement alloc] init];
        ad.creativeKey = @"creativeKey";
        ad.variantKey = @"variantKey";
        ad.placementKey = @"placementKey";
        ad.signature = @"sig";
        ad.auctionType = @"type";
        ad.auctionPrice = @"price";
        ad.adserverRequestId = @"fake-arid";
        ad.auctionWinId = @"fake-awid";
    });

    describe(@"-fireImpressionRequestForPlacementKey:", ^{
        it(@"sends a beacon to the tracking servers", ^{
            [service fireImpressionRequestForPlacementKey:@"placementKey"];

            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"type": @"impressionRequest",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"ua": @"User Agent",
                                                                                         @"ploc": @"specs"});
        });

        context(@"when the pkey is nil", ^{
            it(@"sends a beacon to the tracking servers with a blank pkey", ^{
                [service fireImpressionRequestForPlacementKey:nil];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"",
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs"});
            });
        });
    });

    describe(@"-fireImpressionRequestForPlacementKey:auctionParameterKey:auctionParameterValue:(NSString *)apValue", ^{
        it(@"sends a beacon to the tracking servers", ^{
            [service fireImpressionRequestForPlacementKey:@"placementKey" auctionParameterKey:@"ckey" auctionParameterValue:@"creativeKey"];

            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                         @"ckey": @"creativeKey",
                                                                                         @"type": @"impressionRequest",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"ua": @"User Agent",
                                                                                         @"ploc": @"specs"});
        });

        context(@"when placementKey is nil", ^{
            it(@"sends a beacon to the tracking servers with a blank pkey", ^{
                [service fireImpressionRequestForPlacementKey:nil auctionParameterKey:@"ckey" auctionParameterValue:@"creativeKey"];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"",
                                                                                             @"ckey": @"creativeKey",
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs"});
            });
        });

        context(@"when auctionParameterKey is nil", ^{
            it(@"sends a beacon to the tracking servers with a blank pkey", ^{
                [service fireImpressionRequestForPlacementKey:@"placementKey" auctionParameterKey:nil auctionParameterValue:@"creativeKey"];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs"});
            });
        });

        context(@"when creativeKey is nil", ^{
            it(@"sends a beacon to the tracking servers with a blank ckey", ^{
                [service fireImpressionRequestForPlacementKey:@"placementKey" auctionParameterKey:@"ckey" auctionParameterValue:nil];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"placementKey",
                                                                                             @"ckey": @"",
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs"});
            });
        });

        context(@"when placementKey and creativeKey are nil", ^{
            it(@"sends a beacon to the tracking servers with a blank pkey and ckey", ^{
                [service fireImpressionRequestForPlacementKey:nil auctionParameterKey:@"ckey" auctionParameterValue:nil];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"",
                                                                                             @"ckey": @"",
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs"});
            });
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
                                                                                         @"ua": @"User Agent",
                                                                                         @"pwidth": @"200",
                                                                                         @"pheight": @"100",
                                                                                         @"ploc": @"specs",
                                                                                         @"placementIndex": @"0",
                                                                                         @"as": @"sig",
                                                                                         @"at": @"type",
                                                                                         @"ap": @"price",
                                                                                         @"arid": @"fake-arid",
                                                                                         @"awid": @"fake-awid"});
        });

        describe(@"firing the impression again on the same ad", ^{
            beforeEach(^{
                [(id<CedarDouble>)restClient reset_sent_messages];
                [service fireImpressionForAd:ad adSize:CGSizeMake(200, 100)];
            });

            it(@"does not send another beacon to the tracking servers", ^{
                restClient should_not have_received(@selector(sendBeaconWithParameters:));
            });
        });

        describe(@"when the ad is missing fields", ^{
            beforeEach(^{
                [(id<CedarDouble>)restClient reset_sent_messages];
                ad.placementKey = nil;
                ad.variantKey = nil;
                ad.creativeKey = nil;
                ad.signature = nil;
                ad.auctionType = nil;
                ad.auctionPrice = nil;
                ad.adserverRequestId = nil;
                ad.auctionWinId = nil;
                ad.impressionBeaconFired = NO;
                [service fireImpressionForAd:ad adSize:CGSizeMake(200, 100)];
            });

            it(@"does not send another beacon to the tracking servers", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": @"",
                                                                                             @"ckey": @"",
                                                                                             @"vkey": @"",
                                                                                             @"type": @"impression",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"pwidth": @"200",
                                                                                             @"pheight": @"100",
                                                                                             @"ploc": @"specs",
                                                                                             @"placementIndex": @"0",
                                                                                             @"as": @"",
                                                                                             @"at": @"",
                                                                                             @"ap": @"",
                                                                                             @"arid": @"",
                                                                                             @"awid": @""});
            });
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
                                                                                         @"ua": @"User Agent",
                                                                                         @"pwidth": @"200",
                                                                                         @"pheight": @"100",
                                                                                         @"ploc": @"specs",
                                                                                         @"placementIndex": @"0",
                                                                                         @"as": @"sig",
                                                                                         @"at": @"type",
                                                                                         @"ap": @"price",
                                                                                         @"arid": @"fake-arid",
                                                                                         @"awid": @"fake-awid"});
        });

        describe(@"firing the visible impression again on the same ad", ^{
            beforeEach(^{
                [(id<CedarDouble>)restClient reset_sent_messages];
                [service fireVisibleImpressionForAd:ad adSize:CGSizeMake(200, 100)];
            });

            it(@"does not fire another visible impression beacon", ^{
                restClient should_not have_received(@selector(sendBeaconWithParameters:));
            });
        });
    });

    describe(@"-fireVideoPlayEvent:adSize:", ^{
        __block NSDictionary *parameters;
        __block NSString *expectedUserEvent;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
              @"ckey": @"creativeKey",
              @"vkey": @"variantKey",
              @"type": @"userEvent",
              @"engagement": @"true",
              @"userEvent": expectedUserEvent,
              @"bwidth": @"200",
              @"bheight": @"400",
              @"umtime": @"10",
              @"session": @"AAAA",
              @"uid": @"fakeUUID",
              @"ua": @"User Agent",
              @"pwidth": @"200",
              @"pheight": @"100",
              @"ploc": @"specs",
              @"placementIndex": @"0",
              @"as": @"sig",
              @"at": @"type",
              @"ap": @"price",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid"};
            [service fireVideoPlayEvent:ad adSize:CGSizeMake(200, 100)];


        });

        context(@"when the video is hosted", ^{
            beforeEach(^{
                expectedUserEvent = @"videoPlay";
            });

            it(@"sends a beacon to the tracking servers", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
            });
        });

        context(@"when video is youtube", ^{
            beforeEach(^{
                expectedUserEvent = @"youtubePlay";
                ad.action = STRYouTubeAd;
            });

            it(@"sends a beacon to the tracking servers", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
            });
        });

        context(@"when the video is vine", ^{
            beforeEach(^{
                expectedUserEvent = @"vinePlay";
                ad.action = STRVineAd;
            });

            it(@"sends a beacon to the tracking servers", ^{
                restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
            });
        });


    });

    describe(@"-fireThirdPartyBeacons:", ^{
        context(@"when beacons are not present", ^{
            it(@"should not call the rest client", ^{
                [service fireThirdPartyBeacons:nil forPlacementWithStatus:nil];
                restClient should_not have_received(@selector(sendBeaconWithURL:));
            });
        });

        context(@"when beacons are present", ^{
            context(@"when the placement is live", ^{
                it(@"calls rest client with subsituted timestamp and full url", ^{
                    [service fireThirdPartyBeacons:@[@"//yahoo.com/beacon?=[timestamp]"] forPlacementWithStatus:@"live"];

                    NSURL *targetURL = [NSURL URLWithString:@"http://yahoo.com/beacon?=10"];
                    restClient should have_received(@selector(sendBeaconWithURL:)).with(targetURL);
                });
            });

            context(@"when the placement is pre-live", ^{
                it(@"calls rest client with subsituted timestamp and full url", ^{
                    [service fireThirdPartyBeacons:@[@"//yahoo.com/beacon?=[timestamp]"] forPlacementWithStatus:@"pre-live"];

                    NSURL *targetURL = [NSURL URLWithString:@"http://yahoo.com/beacon?=10"];
                    restClient should_not have_received(@selector(sendBeaconWithURL:)).with(targetURL);
                });
            });
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
                             @"uid": @"fakeUUID",
                             @"ua": @"User Agent",
                             @"ploc": @"specs",
                             @"as": @"sig",
                             @"at": @"type",
                             @"ap": @"price",
                             @"arid": @"fake-arid",
                             @"awid": @"fake-awid"};
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

    describe(@"-fireClickForAd:adSize:", ^{
        __block NSDictionary *parameters;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
                           @"ckey": @"creativeKey",
                           @"vkey": @"variantKey",
                           @"type": @"userEvent",
                           @"engagement": @"true",
                           @"userEvent": @"clickout",
                           @"bwidth": @"200",
                           @"bheight": @"400",
                           @"umtime": @"10",
                           @"session": @"AAAA",
                           @"uid": @"fakeUUID",
                           @"ua": @"User Agent",
                           @"pwidth": @"200",
                           @"pheight": @"100",
                           @"ploc": @"specs",
                           @"placementIndex": @"0",
                           @"as": @"sig",
                           @"at": @"type",
                           @"ap": @"price",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid"};
            [service fireClickForAd:ad adSize:CGSizeMake(200, 100)];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });
});

SPEC_END
