#import "STRAdService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdArticle.h"
#import "STRAdCache.h"
#import "STRAdYouTube.h"
#import "STRAdVine.h"
#import "STRAdClickout.h"
#import "STRAdPinterest.h"
#import "STRAdInstagram.h"
#import "STRBeaconService.h"
#import "STRAdPlacement.h"
#import "STRAdHostedVideo.h"
#import "STRAdInstantHostedVideo.h"
#import "STRAdInstantHostedVideo.h"
#import <AdSupport/AdSupport.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdServiceSpec)

describe(@"STRAdService", ^{
    __block STRAdService *service;
    __block STRRestClient *restClient;
    __block STRNetworkClient *networkClient;
    __block STRInjector *injector;
    __block STRAdCache *adCache;
    __block STRBeaconService *beaconService;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        restClient = nice_fake_for([STRRestClient class]);
        [injector bind:[STRRestClient class] toInstance:restClient];

        networkClient = nice_fake_for([STRNetworkClient class]);
        [injector bind:[STRNetworkClient class] toInstance:networkClient];

        adCache = nice_fake_for([STRAdCache class]);
        [injector bind:[STRAdCache class] toInstance:adCache];

        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        ASIdentifierManager *fakeManager = nice_fake_for([ASIdentifierManager class]);
        spy_on([ASIdentifierManager class]);
        [injector bind:[ASIdentifierManager class] toInstance:fakeManager];
        fakeManager stub_method(@selector(isAdvertisingTrackingEnabled)).and_return(YES);

        NSUUID *fakeId = nice_fake_for([NSUUID class]);
        fakeId stub_method(@selector(UUIDString)).and_return(@"fakeUUID");
        fakeManager stub_method(@selector(advertisingIdentifier)).and_return(fakeId);

        service = [injector getInstance:[STRAdService class]];
    });

    describe(@"fetching an ad", ^{
        __block STRDeferred *restClientDeferred;
        __block STRDeferred *networkClientDeferred;
        __block STRPromise *returnedPromise;
        __block STRAdPlacement *adPlacement;

        beforeEach(^{
            restClientDeferred = [STRDeferred defer];
            restClient stub_method(@selector(getWithParameters:)).and_return(restClientDeferred.promise);

            networkClientDeferred = [STRDeferred defer];
            networkClient stub_method(@selector(get:)).and_return(networkClientDeferred.promise);

            adPlacement = [[STRAdPlacement alloc] init];
            adPlacement.placementKey = @"placementKey";
        });

        describe(@"when an ad is retrieved from the cache", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(YES);
                adCache stub_method(@selector(fetchCachedAdForPlacement:)).and_return(ad);
                adCache stub_method(@selector(shouldBeginFetchForPlacement:)).and_return(NO);

                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"does not make a request to the ad server", ^{
                restClient should_not have_received(@selector(getWithParameters:));
            });

            it(@"does not fire an impression request", ^{
                beaconService should_not have_received(@selector(fireImpressionRequestForPlacementKey:));
            });

            it(@"does not make a request to the image server", ^{
                networkClient should_not have_received(@selector(get:));
            });

            it(@"returns a promise that is resolved with the cached ad", ^{
                returnedPromise.value should equal(ad);
            });
        });
        
        xdescribe(@"when an ad is retrieved from the cache, but there are no more ads in the queue", ^{
            __block STRAdvertisement *ad;
            
            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(YES);
                adCache stub_method(@selector(fetchCachedAdForPlacement:)).and_return(ad);
                adCache stub_method(@selector(shouldBeginFetchForPlacement:)).and_return(YES);
                
                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });
            
            it(@"does not make a request to the ad server", ^{
                restClient should_not have_received(@selector(getWithParameters:));
            });
            
            it(@"does not fire an impression request", ^{
                beaconService should_not have_received(@selector(fireImpressionRequestForPlacementKey:));
            });
            
            it(@"does not make a request to the image server", ^{
                networkClient should_not have_received(@selector(get:));
            });
            
            it(@"returns a promise that is resolved with the cached ad", ^{
                returnedPromise.value should equal(ad);
            });
        });

        describe(@"when an ad is cached for longer than the timeout", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);

                adCache stub_method(@selector(fetchCachedAdForPlacement:)).and_return(ad);
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(NO);

                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"makes a request to the ad server", ^{
                restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey", @"appName": @"specs", @"appId": @"com.sharethrough.specs", @"uid" : @"fakeUUID" });
            });

            describe(@"when the appName and bundle id are nil", ^{
                __block NSBundle *fakeBundle;
                beforeEach(^{
                    fakeBundle = nice_fake_for([NSBundle class]);
                    fakeBundle stub_method(@selector(objectForInfoDictionaryKey:)).and_return(nil);

                    spy_on([NSBundle class]);
                    [NSBundle class] stub_method(@selector(mainBundle)).and_return(fakeBundle);
                });

                it(@"makes a request to the ad server", ^{
                    [(id<CedarDouble>)restClient reset_sent_messages];
                    returnedPromise = [service fetchAdForPlacement:adPlacement];

                    restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey", @"appName": @"", @"appId": @"", @"uid" : @"fakeUUID" });
                });
            });

            it(@"fires an impression request beacon", ^{
                beaconService should have_received(@selector(fireImpressionRequestForPlacementKey:)).with(@"placementKey");
            });

            it(@"returns an unresolved promise", ^{
                returnedPromise should_not be_nil;
                returnedPromise.value should be_nil;
            });

            describe(@"when the ad server unsuccessfully responds", ^{
                it(@"returns the cached ad", ^{
                    [restClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];

                    returnedPromise.value should equal(ad);
                });
            });
        });

        describe(@"when there is a pending ad request", ^{
            beforeEach(^{
                adCache stub_method(@selector(fetchCachedAdForPlacement:));
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(NO);
                adCache stub_method(@selector(pendingAdRequestInProgressForPlacement:)).and_return(YES);

                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"returns a pendingRequestInProgress error", ^{
                returnedPromise should_not be_nil;
                returnedPromise.error should_not be_nil;
                returnedPromise.error.code should equal(kRequestInProgress);
            });
        });

        describe(@"when no ad is cached for the given placement key", ^{
            beforeEach(^{
                adCache stub_method(@selector(fetchCachedAdForPlacement:));
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(NO);

                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"makes a request to the ad server", ^{
                restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey", @"appName": @"specs", @"appId": @"com.sharethrough.specs", @"uid" : @"fakeUUID" });
            });

            it(@"fires an impression request beacon", ^{
                beaconService should have_received(@selector(fireImpressionRequestForPlacementKey:)).with(@"placementKey");
            });

            it(@"returns an unresolved promise", ^{
                returnedPromise should_not be_nil;
                returnedPromise.value should be_nil;
            });

            describe(@"when the ad server responds with an ad", ^{
                void(^afterSuccessfulAdFetchedSpecs)(Class expectedAdClass, NSString *expectedAction) = ^(Class expectedAdClass, NSString *expectedAction) {

                    it(@"makes a request for the thumbnail image", ^{
                        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"]];
                        networkClient should have_received(@selector(get:)).with(request);
                    });

                    it(@"still has the returned promise as unresolved", ^{
                        returnedPromise should_not be_nil;
                        returnedPromise.value should be_nil;
                    });

                    describe(@"when the image is loaded successfully", ^{
                        beforeEach(^{
                            [networkClientDeferred resolveWithValue:UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"])];
                        });

                        it(@"saves the ad in the cache", ^{
                            adCache should have_received(@selector(saveAds:forPlacement:andInitializeAtIndex:));
                        });

                        it(@"resolves the returned promise with an advertisement from the cache", ^{
                            adCache should have_received(@selector(fetchCachedAdForPlacement:));
//                            returnedPromise.value should_not be_nil;
//                            returnedPromise.value should be_instance_of(expectedAdClass);
//
//                            STRAdvertisement *ad = (STRAdvertisement *) returnedPromise.value;
//                            ad.advertiser should equal(@"Brand X");
//                            ad.title should equal(@"Meet Porter. He's a Dog.");
//                            ad.adDescription should equal(@"Dogs this smart deserve a home.");
//                            [ad.mediaURL absoluteString] should equal(@"http://www.google.com");
//                            [ad.shareURL absoluteString] should equal(@"http://bit.ly/14hfvXG");
//                            ad.creativeKey should equal(@"imagination");
//                            ad.variantKey should equal(@"variation");
//                            ad.placementKey should equal(@"placementKey");
//                            ad.signature should equal(@"fakeSignature");
//                            ad.auctionType should equal(@"type");
//                            ad.auctionPrice should equal(@"1.0");
//                            ad.action should equal(expectedAction);
//
//                            ad.thirdPartyBeaconsForVisibility should equal(@[@"//reddit.com/ad?time=[timestamp]"]);
//                            ad.thirdPartyBeaconsForClick should equal(@[@"//yahoo.com/dance?danced_at=[timestamp]"]);
//                            ad.thirdPartyBeaconsForPlay should equal(@[@"//cupcakes.com/yum?allgone=[timestamp]"]);
//
//                            UIImagePNGRepresentation(ad.thumbnailImage) should equal(UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]));
                        });
                    });

//                    describe(@"when the image can't be loaded", ^{
//                        it(@"rejects the returned promise", ^{
//                            [networkClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];
//                            
//                            returnedPromise.error should_not be_nil;
//                        });
//                    });
                };

                __block NSDictionary *responseData;

                beforeEach(^{
                    responseData = @{
                                     @"placement": [@{
                                             @"allow_instant_play": @false
                                     } mutableCopy],
                                     @"creatives": @[[@{ @"signature": @"fakeSignature",
                                                       @"price": @"1.0",
                                                       @"priceType": @"type",
                                                       @"creative": [@{
                                                                       @"description": @"Dogs this smart deserve a home.",
                                                                       @"thumbnail_url": @"http://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg",
                                                                       @"title": @"Meet Porter. He's a Dog.",
                                                                       @"advertiser": @"Brand X",
                                                                       @"media_url": @"http://www.google.com",
                                                                       @"share_url": @"http://bit.ly/14hfvXG",
                                                                       @"creative_key": @"imagination",
                                                                       @"variant_key": @"variation",
                                                                       @"beacons": @{@"visible": @[@"//reddit.com/ad?time=[timestamp]"],
                                                                                     @"click": @[@"//yahoo.com/dance?danced_at=[timestamp]"],
                                                                                     @"play": @[@"//cupcakes.com/yum?allgone=[timestamp]"]},
                                                                       } mutableCopy]
                                                         } mutableCopy]
                                                     ]
                                    };
                });

                describe(@"when the ad server responds with a Vine ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"vine";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdVine class], @"vine");
                });

                describe(@"when the ad server successfully responds with a YouTube ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"video";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdYouTube class], @"video");
                });

                describe(@"when the ad server successfully responds with a clickout ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"clickout";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdClickout class], @"clickout");
                });
                
                describe(@"when the ad server successfully responds with a pinterest ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"pinterest";
                        [restClientDeferred resolveWithValue:responseData];
                    });
                    
                    afterSuccessfulAdFetchedSpecs([STRAdPinterest class], @"pinterest");
                });
                
                describe(@"when the ad server successfully responds with a instagram ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"instagram";
                        [restClientDeferred resolveWithValue:responseData];
                    });
                    
                    afterSuccessfulAdFetchedSpecs([STRAdInstagram class], @"instagram");
                });

                describe(@"when the ad server successfully responds with an article ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"article";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdArticle class], @"article");
                });

                describe(@"when the ad server successfully responds with an unknown ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"unknown";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdvertisement class], @"unknown");
                });

                describe(@"when the ad server successfully responds with hosted video ad", ^{

                    describe(@"when the placement is not instant play", ^{
                        beforeEach(^{
                            responseData[@"creatives"][0][@"creative"][@"action"] = @"hosted-video";
                            [restClientDeferred resolveWithValue:responseData];
                        });

                        afterSuccessfulAdFetchedSpecs([STRAdHostedVideo class], @"hosted-video");
                    });

                    describe(@"when the placement is instant play", ^{
                        beforeEach(^{
                            responseData[@"placement"][@"allow_instant_play"] = @YES;
                            responseData[@"creatives"][0][@"creative"][@"action"] = @"hosted-video";
                            [restClientDeferred resolveWithValue:responseData];
                        });

                        afterSuccessfulAdFetchedSpecs([STRAdHostedVideo class], @"hosted-video");
                    });
                });
            });

            describe(@"when the ad server responds without a protocol", ^{
                beforeEach(^{
                    [restClientDeferred resolveWithValue:@{ @"creatives": @[
                                                                    @{@"creative":
                                                                          @{@"thumbnail_url": @"//i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"},
                                                                      }
                                                                    ]
                                                            }];
                });

                it(@"makes a request for the thumbnail image and inserts the protocol", ^{
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"]];
                    networkClient should have_received(@selector(get:)).with(request);
                });
            });

            describe(@"when the ad server responds with no creatives", ^{
                it(@"rejects the returned promise", ^{
                    [restClientDeferred resolveWithValue:@{
                                                           @"creatives": @[]
                                                           }];

                    returnedPromise.error should_not be_nil;
                });

                it(@"resets the pending ad request", ^{
                    [restClientDeferred resolveWithValue:@{
                                                           @"creatives": @[]
                                                           }];
                    adCache should have_received(@selector(clearPendingAdRequestForPlacement:)).with(adPlacement.placementKey);
                });
            });
            
            describe(@"when the ad server unsuccessfully responds", ^{
                it(@"rejects the returned promise", ^{
                    [restClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];
                    
                    returnedPromise.error should_not be_nil;
                });
            });
        });

    });

    describe(@"fetching a specific creative or campaign", ^{
        __block STRDeferred *restClientDeferred;
        __block STRDeferred *networkClientDeferred;
        __block STRPromise *returnedPromise;
        __block STRAdPlacement *adPlacement;

        beforeEach(^{
            restClientDeferred = [STRDeferred defer];
            restClient stub_method(@selector(getWithParameters:)).and_return(restClientDeferred.promise);

            networkClientDeferred = [STRDeferred defer];
            networkClient stub_method(@selector(get:)).and_return(networkClientDeferred.promise);

            adPlacement = [[STRAdPlacement alloc] init];
            adPlacement.placementKey = @"placementKey";
        });

        describe(@"when an ad is retrieved from the cache", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);
                adCache stub_method(@selector(fetchCachedAdForPlacementKey:CreativeKey:)).and_return(ad);

                returnedPromise = [service fetchAdForPlacement:adPlacement auctionParameterKey:@"creative_key" auctionParameterValue:@"creativeKey"];
            });

            it(@"does not make a request to the ad server", ^{
                restClient should_not have_received(@selector(getWithParameters:));
            });

            it(@"does not fire an impression request", ^{
                beaconService should_not have_received(@selector(fireImpressionRequestForPlacementKey:));
            });

            it(@"does not make a request to the image server", ^{
                networkClient should_not have_received(@selector(get:));
            });

            it(@"returns a promise that is resolved with the cached ad", ^{
                returnedPromise.value should equal(ad);
            });
        });

        describe(@"when it's not a creative key", ^{
            it(@"does not call to the ad cache", ^{
                returnedPromise = [service fetchAdForPlacement:adPlacement auctionParameterKey:@"campaign_key" auctionParameterValue:@"campaignKey"];
                adCache should_not have_received(@selector(fetchCachedAdForPlacementKey:CreativeKey:));
            });
        });

        describe(@"when an ad is retrieved from the cache, but there are no more ads in the queue", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(YES);
                adCache stub_method(@selector(fetchCachedAdForPlacement:)).and_return(ad);
                adCache stub_method(@selector(shouldBeginFetchForPlacement:)).and_return(YES);

                adPlacement.isDirectSold = YES;
                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"does not make a request to the ad server", ^{
                restClient should_not have_received(@selector(getWithParameters:));
            });

            it(@"does not fire an impression request", ^{
                beaconService should_not have_received(@selector(fireImpressionRequestForPlacementKey:));
            });

            it(@"does not make a request to the image server", ^{
                networkClient should_not have_received(@selector(get:));
            });

            it(@"returns a promise that is resolved with the cached ad", ^{
                returnedPromise.value should equal(ad);
            });
        });

        describe(@"when an ad is cached for longer than the timeout", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);

                adCache stub_method(@selector(fetchCachedAdForPlacement:)).and_return(ad);
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(NO);

                returnedPromise = [service fetchAdForPlacement:adPlacement auctionParameterKey:@"creative_key" auctionParameterValue:@"creativeKey"];
            });

            it(@"makes a request to the ad server", ^{
                restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey", @"appName": @"specs", @"appId": @"com.sharethrough.specs", @"creative_key": @"creativeKey", @"uid" : @"fakeUUID" });
            });

            it(@"fires an impression request beacon", ^{
                beaconService should have_received(@selector(fireImpressionRequestForPlacementKey:auctionParameterKey:auctionParameterValue:)).with(@"placementKey", @"creative_key", @"creativeKey");
            });

            it(@"returns an unresolved promise", ^{
                returnedPromise should_not be_nil;
                returnedPromise.value should be_nil;
            });

            describe(@"when the ad server unsuccessfully responds", ^{
                it(@"returns the cached ad", ^{
                    [restClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];

                    returnedPromise.value should equal(ad);
                });
            });
        });

        xdescribe(@"when there is a pending ad request", ^{
            beforeEach(^{
                adCache stub_method(@selector(fetchCachedAdForPlacement:));
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(NO);
                adCache stub_method(@selector(pendingAdRequestInProgressForPlacement:)).and_return(YES);

                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"returns a pendingRequestInProgress error", ^{
                returnedPromise should_not be_nil;
                returnedPromise.error should_not be_nil;
                returnedPromise.error.code should equal(kRequestInProgress);
            });
        });

        xdescribe(@"when no ad is cached for the given placement key", ^{
            beforeEach(^{
                adCache stub_method(@selector(fetchCachedAdForPlacement:));
                adCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(NO);

                returnedPromise = [service fetchAdForPlacement:adPlacement];
            });

            it(@"makes a request to the ad server", ^{
                restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey", @"appName": @"specs", @"appId": @"com.sharethrough.specs"});
            });

            it(@"fires an impression request beacon", ^{
                beaconService should have_received(@selector(fireImpressionRequestForPlacementKey:)).with(@"placementKey");
            });

            it(@"returns an unresolved promise", ^{
                returnedPromise should_not be_nil;
                returnedPromise.value should be_nil;
            });

            describe(@"when the ad server responds with an ad", ^{
                void(^afterSuccessfulAdFetchedSpecs)(Class expectedAdClass, NSString *expectedAction) = ^(Class expectedAdClass, NSString *expectedAction) {

                    it(@"makes a request for the thumbnail image", ^{
                        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"]];
                        networkClient should have_received(@selector(get:)).with(request);
                    });

                    it(@"still has the returned promise as unresolved", ^{
                        returnedPromise should_not be_nil;
                        returnedPromise.value should be_nil;
                    });

                    describe(@"when the image is loaded successfully", ^{
                        beforeEach(^{
                            [networkClientDeferred resolveWithValue:UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"])];
                        });

                        it(@"saves the ad in the cache", ^{
                            adCache should have_received(@selector(saveAds:forPlacement:andInitializeAtIndex:));
                        });

                        it(@"resolves the returned promise with an advertisement from the cache", ^{
                            adCache should have_received(@selector(fetchCachedAdForPlacement:));
                            //                            returnedPromise.value should_not be_nil;
                            //                            returnedPromise.value should be_instance_of(expectedAdClass);
                            //
                            //                            STRAdvertisement *ad = (STRAdvertisement *) returnedPromise.value;
                            //                            ad.advertiser should equal(@"Brand X");
                            //                            ad.title should equal(@"Meet Porter. He's a Dog.");
                            //                            ad.adDescription should equal(@"Dogs this smart deserve a home.");
                            //                            [ad.mediaURL absoluteString] should equal(@"http://www.google.com");
                            //                            [ad.shareURL absoluteString] should equal(@"http://bit.ly/14hfvXG");
                            //                            ad.creativeKey should equal(@"imagination");
                            //                            ad.variantKey should equal(@"variation");
                            //                            ad.placementKey should equal(@"placementKey");
                            //                            ad.signature should equal(@"fakeSignature");
                            //                            ad.auctionType should equal(@"type");
                            //                            ad.auctionPrice should equal(@"1.0");
                            //                            ad.action should equal(expectedAction);
                            //
                            //                            ad.thirdPartyBeaconsForVisibility should equal(@[@"//reddit.com/ad?time=[timestamp]"]);
                            //                            ad.thirdPartyBeaconsForClick should equal(@[@"//yahoo.com/dance?danced_at=[timestamp]"]);
                            //                            ad.thirdPartyBeaconsForPlay should equal(@[@"//cupcakes.com/yum?allgone=[timestamp]"]);
                            //
                            //                            UIImagePNGRepresentation(ad.thumbnailImage) should equal(UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]));
                        });
                    });

                    //                    describe(@"when the image can't be loaded", ^{
                    //                        it(@"rejects the returned promise", ^{
                    //                            [networkClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];
                    //
                    //                            returnedPromise.error should_not be_nil;
                    //                        });
                    //                    });
                };

                __block NSDictionary *responseData;

                beforeEach(^{
                    responseData = @{
                                     @"creatives": @[[@{ @"signature": @"fakeSignature",
                                                         @"price": @"1.0",
                                                         @"priceType": @"type",
                                                         @"creative": [@{
                                                                         @"description": @"Dogs this smart deserve a home.",
                                                                         @"thumbnail_url": @"http://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg",
                                                                         @"title": @"Meet Porter. He's a Dog.",
                                                                         @"advertiser": @"Brand X",
                                                                         @"media_url": @"http://www.google.com",
                                                                         @"share_url": @"http://bit.ly/14hfvXG",
                                                                         @"creative_key": @"imagination",
                                                                         @"variant_key": @"variation",
                                                                         @"beacons": @{@"visible": @[@"//reddit.com/ad?time=[timestamp]"],
                                                                                       @"click": @[@"//yahoo.com/dance?danced_at=[timestamp]"],
                                                                                       @"play": @[@"//cupcakes.com/yum?allgone=[timestamp]"]},
                                                                         } mutableCopy]
                                                         } mutableCopy]
                                                     ]
                                     };
                });

                describe(@"when the ad server responds with a Vine ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"vine";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdVine class], @"vine");
                });

                describe(@"when the ad server successfully responds with a YouTube ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"video";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdYouTube class], @"video");
                });

                describe(@"when the ad server successfully responds with a clickout ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"clickout";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdClickout class], @"clickout");
                });

                describe(@"when the ad server successfully responds with a pinterest ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"pinterest";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdPinterest class], @"pinterest");
                });

                describe(@"when the ad server successfully responds with a instagram ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"instagram";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdInstagram class], @"instagram");
                });

                describe(@"when the ad server successfully responds with an article ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"article";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRClickoutAd class], @"article");
                });

                describe(@"when the ad server successfully responds with an article ad", ^{
                    beforeEach(^{
                        responseData[@"creatives"][0][@"creative"][@"action"] = @"unknown";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRClickoutAd class], @"unknown");
                });
            });

            describe(@"when the ad server responds without a protocol", ^{
                beforeEach(^{
                    [restClientDeferred resolveWithValue:@{ @"creatives": @[
                                                                    @{@"creative":
                                                                          @{@"thumbnail_url": @"//i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"},
                                                                      }
                                                                    ]
                                                            }];
                });

                it(@"makes a request for the thumbnail image and inserts the protocol", ^{
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"]];
                    networkClient should have_received(@selector(get:)).with(request);
                });
            });

            describe(@"when the ad server unsuccessfully responds", ^{
                it(@"rejects the returned promise", ^{
                    [restClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];

                    returnedPromise.error should_not be_nil;
                });
            });
        });
    });

    describe(@"- (STRAdvertisement *)adForCreative:inPlacement:", ^{
        __block NSDictionary *creativeJSON, *placementJSON;

        describe(@"when the action is clickout", ^{
            beforeEach(^{
                creativeJSON = @{
                                 @"action": @"clickout"
                                 };
            });

            it(@"returns a clickout", ^{
                STRAdvertisement *ad = [service adForCreative:creativeJSON inPlacement:placementJSON];
                ad should be_instance_of([STRAdClickout class]);
            });
        });

        describe(@"when the action is hoted-video", ^{
            describe(@"when the placement doesn't allow instant play", ^{
                beforeEach(^{
                    creativeJSON = @{
                                     @"action": @"hosted-video",
                                     @"force_click_to_play": @NO
                                     };
                    placementJSON = @{
                                      @"allowInstantPlay": @NO
                                      };
                });

                it(@"returns a hosted video ad", ^{
                    STRAdvertisement *ad = [service adForCreative:creativeJSON inPlacement:placementJSON];
                    ad should be_instance_of([STRAdHostedVideo class]);
                });
            });

            describe(@"when the creative forces click to play", ^{
                beforeEach(^{
                    creativeJSON = @{
                                     @"action": @"hosted-video",
                                     @"force_click_to_play": @YES
                                     };
                    placementJSON = @{
                                      @"allowInstantPlay": @YES
                                      };
                });

                it(@"returns a hosted video ad", ^{
                    STRAdvertisement *ad = [service adForCreative:creativeJSON inPlacement:placementJSON];
                    ad should be_instance_of([STRAdHostedVideo class]);
                });
            });

            describe(@"when the placement allows instant play", ^{
                beforeEach(^{
                    creativeJSON = @{
                                     @"action": @"hosted-video",
                                     @"force_click_to_play": @NO
                                     };
                    placementJSON = @{
                                      @"allowInstantPlay": @YES
                                      };
                });

                it(@"returns a instant video ad", ^{
                    STRAdvertisement *ad = [service adForCreative:creativeJSON inPlacement:placementJSON];
                    ad should be_instance_of([STRAdInstantHostedVideo class]);
                });
            });
        });
    });
});

SPEC_END
