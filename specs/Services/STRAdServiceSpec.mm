#import "STRAdService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdCache.h"
#import "STRAdYouTube.h"
#import "STRAdVine.h"
#import "STRAdClickout.h"
#import "STRBeaconService.h"

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

        service = [injector getInstance:[STRAdService class]];
    });

    describe(@"fetching an ad", ^{
        __block STRDeferred *restClientDeferred;
        __block STRDeferred *networkClientDeferred;
        __block STRPromise *returnedPromise;

        beforeEach(^{
            restClientDeferred = [STRDeferred defer];
            restClient stub_method(@selector(getWithParameters:)).and_return(restClientDeferred.promise);

            networkClientDeferred = [STRDeferred defer];
            networkClient stub_method(@selector(get:)).and_return(networkClientDeferred.promise);
        });

        describe(@"when an ad is retrieved from the cache", ^{
            __block STRAdvertisement *ad;

            beforeEach(^{
                ad = nice_fake_for([STRAdvertisement class]);
                adCache stub_method(@selector(fetchCachedAdForPlacementKey:)).with(@"placementKey").and_return(ad);

                returnedPromise = [service fetchAdForPlacementKey:@"placementKey"];
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

        describe(@"when no ad is cached for the given placement key", ^{
            beforeEach(^{
                adCache stub_method(@selector(fetchCachedAdForPlacementKey:)).with(@"placementKey");

                returnedPromise = [service fetchAdForPlacementKey:@"placementKey"];
            });

            it(@"makes a request to the ad server", ^{
                restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey"});
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
                            adCache should have_received(@selector(saveAd:)).with(returnedPromise.value);
                        });

                        it(@"resolves the returned promise with an advertisement", ^{
                            returnedPromise.value should_not be_nil;
                            returnedPromise.value should be_instance_of(expectedAdClass);

                            STRAdvertisement *ad = (STRAdvertisement *) returnedPromise.value;
                            ad.advertiser should equal(@"Brand X");
                            ad.title should equal(@"Meet Porter. He's a Dog.");
                            ad.adDescription should equal(@"Dogs this smart deserve a home.");
                            [ad.mediaURL absoluteString] should equal(@"http://www.google.com");
                            [ad.shareURL absoluteString] should equal(@"http://bit.ly/14hfvXG");
                            ad.creativeKey should equal(@"imagination");
                            ad.variantKey should equal(@"variation");
                            ad.placementKey should equal(@"placementKey");
                            ad.signature should equal(@"fakeSignature");
                            ad.auctionType should equal(@"type");
                            ad.auctionPrice should equal(@"1.0");
                            ad.action should equal(expectedAction);

                            ad.thirdPartyBeaconsForVisibility should equal(@[@"//reddit.com/ad?time=[timestamp]"]);
                            ad.thirdPartyBeaconsForClick should equal(@[@"//yahoo.com/dance?danced_at=[timestamp]"]);
                            ad.thirdPartyBeaconsForPlay should equal(@[@"//cupcakes.com/yum?allgone=[timestamp]"]);

                            UIImagePNGRepresentation(ad.thumbnailImage) should equal(UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]));
                        });
                    });

                    describe(@"when the image can't be loaded", ^{
                        it(@"rejects the returned promise", ^{
                            [networkClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];
                            
                            returnedPromise.error should_not be_nil;
                        });
                    });
                };

                __block NSDictionary *responseData;

                beforeEach(^{
                    responseData = @{ @"signature": @"fakeSignature",
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
                                      };
                });

                describe(@"when the ad server responds with a Vine ad", ^{
                    beforeEach(^{
                        responseData[@"creative"][@"action"] = @"vine";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdVine class], @"vine");
                });

                describe(@"when the ad server successfully responds with a YouTube ad", ^{
                    beforeEach(^{
                        responseData[@"creative"][@"action"] = @"video";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdYouTube class], @"video");
                });

                describe(@"when the ad server successfully responds with a clickout ad", ^{
                    beforeEach(^{
                        responseData[@"creative"][@"action"] = @"clickout";
                        [restClientDeferred resolveWithValue:responseData];
                    });

                    afterSuccessfulAdFetchedSpecs([STRAdClickout class], @"clickout");
                });

            });

            describe(@"when the ad server responds without a protocol", ^{
                beforeEach(^{
                    [restClientDeferred resolveWithValue:@{ @"creative":
                                                                @{@"thumbnail_url": @"//i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg"},
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
});

SPEC_END
