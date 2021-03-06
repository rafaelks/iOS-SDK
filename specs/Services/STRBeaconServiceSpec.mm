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
#import "STRAdPlacement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRBeaconServiceSpec)

describe(@"STRBeaconService", ^{
    __block STRBeaconService *service;
    __block STRRestClient *restClient;
    __block STRInjector *injector;
    __block STRAdvertisement *ad;
    __block STRAdPlacement *adPlacement;

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

        adPlacement = [[STRAdPlacement alloc] init];
        adPlacement.placementKey = @"placementKey";
        adPlacement.mrid = @"mrid";

        ad = [[STRAdvertisement alloc] init];
        ad.creativeKey = @"creativeKey";
        ad.variantKey = @"variantKey";
        ad.placementKey = @"placementKey";
        ad.adserverRequestId = @"fake-arid";
        ad.auctionWinId = @"fake-awid";
        ad.dealId = @"fake-dealId";
        ad.mrid = adPlacement.mrid;
    });

    describe(@"-fireImpressionRequestForPlacement:", ^{
        it(@"sends a beacon to the tracking servers", ^{
            [service fireImpressionRequestForPlacement:adPlacement];

            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": adPlacement.placementKey,
                                                                                         @"type": @"impressionRequest",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"ua": @"User Agent",
                                                                                         @"ploc": @"specs",
                                                                                         @"mrid": @"mrid"});
        });
    });

    describe(@"-fireImpressionRequestForPlacement:auctionParameterKey:auctionParameterValue:(NSString *)apValue", ^{
        it(@"sends a beacon to the tracking servers", ^{
            [service fireImpressionRequestForPlacement:adPlacement auctionParameterKey:@"ckey" auctionParameterValue:@"creativeKey"];

            restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": adPlacement.placementKey,
                                                                                         @"ckey": @"creativeKey",
                                                                                         @"type": @"impressionRequest",
                                                                                         @"bwidth": @"200",
                                                                                         @"bheight": @"400",
                                                                                         @"umtime": @"10",
                                                                                         @"session": @"AAAA",
                                                                                         @"uid": @"fakeUUID",
                                                                                         @"ua": @"User Agent",
                                                                                         @"ploc": @"specs",
                                                                                         @"mrid": @"mrid"});
        });

        context(@"when auctionParameterKey is nil", ^{
            it(@"sends a beacon to the tracking servers with a blank pkey", ^{
                [service fireImpressionRequestForPlacement:adPlacement auctionParameterKey:nil auctionParameterValue:@"creativeKey"];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": adPlacement.placementKey,
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs",
                                                                                             @"mrid": @"mrid"});
            });
        });

        context(@"when creativeKey is nil", ^{
            it(@"sends a beacon to the tracking servers with a blank ckey", ^{
                [service fireImpressionRequestForPlacement:adPlacement auctionParameterKey:@"ckey" auctionParameterValue:nil];

                restClient should have_received(@selector(sendBeaconWithParameters:)).with(@{@"pkey": adPlacement.placementKey,
                                                                                             @"ckey": @"",
                                                                                             @"type": @"impressionRequest",
                                                                                             @"bwidth": @"200",
                                                                                             @"bheight": @"400",
                                                                                             @"umtime": @"10",
                                                                                             @"session": @"AAAA",
                                                                                             @"uid": @"fakeUUID",
                                                                                             @"ua": @"User Agent",
                                                                                             @"ploc": @"specs",
                                                                                             @"mrid": @"mrid"});
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
                                                                                         @"arid": @"fake-arid",
                                                                                         @"awid": @"fake-awid",
                                                                                         @"deal_id": @"fake-dealId",
                                                                                         @"mrid": @"mrid"});
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
                ad.adserverRequestId = nil;
                ad.auctionWinId = nil;
                ad.impressionBeaconFired = NO;
                ad.dealId = nil;
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
                                                                                             @"arid": @"",
                                                                                             @"awid": @"",
                                                                                             @"mrid": @"mrid"});
            });
        });
    });

    describe(@"-fireVisibleImpressionForAd:adSize:", ^{
        __block BOOL beaconFired;
        beforeEach(^{
            beaconFired = [service fireVisibleImpressionForAd:ad adSize:CGSizeMake(200, 100)];
        });

        it(@"sends a beacon to the tracking servers", ^{
            beaconFired should be_truthy;
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
                                                                                         @"arid": @"fake-arid",
                                                                                         @"awid": @"fake-awid",
                                                                                         @"deal_id": @"fake-dealId",
                                                                                         @"mrid": @"mrid"});
        });

        describe(@"firing the visible impression again on the same ad", ^{
            beforeEach(^{
                [(id<CedarDouble>)restClient reset_sent_messages];
                beaconFired = [service fireVisibleImpressionForAd:ad adSize:CGSizeMake(200, 100)];
            });

            it(@"does not fire another visible impression beacon", ^{
                beaconFired should be_falsy;
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
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
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

                    restClient should_not have_received(@selector(sendBeaconWithURL:));
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
                             @"arid": @"fake-arid",
                             @"awid": @"fake-awid",
                             @"deal_id": @"fake-dealId",
                             @"mrid": @"mrid"};
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
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
            [service fireClickForAd:ad adSize:CGSizeMake(200, 100)];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });

    describe(@"-fireArticleViewForAd:", ^{
        __block NSDictionary *parameters;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
                           @"ckey": @"creativeKey",
                           @"vkey": @"variantKey",
                           @"type": @"userEvent",
                           @"engagement": @"true",
                           @"userEvent": @"articleView",
                           @"bwidth": @"200",
                           @"bheight": @"400",
                           @"umtime": @"10",
                           @"session": @"AAAA",
                           @"uid": @"fakeUUID",
                           @"ua": @"User Agent",
                           @"ploc": @"specs",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
            [service fireArticleViewForAd:ad];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });

    describe(@"-fireArticleDurationForAd:withDuration:", ^{
        __block NSDictionary *parameters;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
                           @"ckey": @"creativeKey",
                           @"vkey": @"variantKey",
                           @"type": @"userEvent",
                           @"duration": @"10998.000000",
                           @"engagement": @"true",
                           @"userEvent": @"articleViewDuration",
                           @"bwidth": @"200",
                           @"bheight": @"400",
                           @"umtime": @"10",
                           @"session": @"AAAA",
                           @"uid": @"fakeUUID",
                           @"ua": @"User Agent",
                           @"ploc": @"specs",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
            [service fireArticleDurationForAd:ad withDuration:10.9980];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });

    describe(@"-fireSilentAutoPlayDurationForAd:withDuration:", ^{
        __block NSDictionary *parameters;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
                           @"ckey": @"creativeKey",
                           @"vkey": @"variantKey",
                           @"type": @"silentAutoPlayDuration",
                           @"duration" : @"3000",
                           @"bwidth": @"200",
                           @"bheight": @"400",
                           @"umtime": @"10",
                           @"session": @"AAAA",
                           @"uid": @"fakeUUID",
                           @"ua": @"User Agent",
                           @"ploc": @"specs",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
            [service fireSilentAutoPlayDurationForAd:ad withDuration:3000.0];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });

    describe(@"-fireAutoPlayVideoEngagementForAd:withDuration:", ^{
        __block NSDictionary *parameters;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
                           @"ckey": @"creativeKey",
                           @"vkey": @"variantKey",
                           @"type": @"userEvent",
                           @"engagement": @"true",
                           @"userEvent": @"autoplayVideoEngagement",
                           @"duration" : @"10323.330000",
                           @"bwidth": @"200",
                           @"bheight": @"400",
                           @"umtime": @"10",
                           @"session": @"AAAA",
                           @"uid": @"fakeUUID",
                           @"ua": @"User Agent",
                           @"ploc": @"specs",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
            [service fireAutoPlayVideoEngagementForAd:ad withDuration:10323.33];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });

    describe(@"-fireVideoViewDurationForAd:withDuration:isSilent:", ^{
        __block NSDictionary *parameters;

        subjectAction(^{
            parameters = @{@"pkey": @"placementKey",
                           @"ckey": @"creativeKey",
                           @"vkey": @"variantKey",
                           @"type": @"videoViewDuration",
                           @"duration" : @"10323.330000",
                           @"silent": @"true",
                           @"bwidth": @"200",
                           @"bheight": @"400",
                           @"umtime": @"10",
                           @"session": @"AAAA",
                           @"uid": @"fakeUUID",
                           @"ua": @"User Agent",
                           @"ploc": @"specs",
                           @"arid": @"fake-arid",
                           @"awid": @"fake-awid",
                           @"deal_id": @"fake-dealId",
                           @"mrid": @"mrid"};
            [service fireVideoViewDurationForAd:ad withDuration:10.32333 isSilent:YES];
        });

        it(@"sends a beacon to the tracking servers", ^{
            restClient should have_received(@selector(sendBeaconWithParameters:)).with(parameters);
        });
    });
});

SPEC_END
