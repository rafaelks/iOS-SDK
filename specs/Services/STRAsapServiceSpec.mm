//
//  STRAsapServiceSpec.mm
//  SharethroughSDK
//
//  Created by Mark Meyer on 5/16/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "STRAsapService.h"

#import <AdSupport/AdSupport.h>

#import "STRAdCache.h"
#import "STRAdPlacement.h"
#import "STRAdvertisement.h"
#import "STRDeferred.h"
#import "STRLogging.h"
#import "STRPromise.h"
#import "STRRestClient.h"
#import "STRAppModule.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAsapServiceSpec)

describe(@"STRAsapService", ^{
    __block STRAsapService *asapService;
    __block STRRestClient *restClient;
    __block STRAdCache *adCache;
    __block STRInjector *injector;
    __block STRAdvertisement *ad;

    beforeEach(^{
        ad = nice_fake_for([STRAdvertisement class]);

        injector = [STRInjector injectorForModule:[STRAppModule new]];

        restClient = nice_fake_for([STRRestClient class]);
        [injector bind:[STRRestClient class] toInstance:restClient];

        adCache = nice_fake_for([STRAdCache class]);
        [injector bind:[STRAdCache class] toInstance:adCache];

        ASIdentifierManager *fakeManager = nice_fake_for([ASIdentifierManager class]);
        spy_on([ASIdentifierManager class]);
        [injector bind:[ASIdentifierManager class] toInstance:fakeManager];
        fakeManager stub_method(@selector(isAdvertisingTrackingEnabled)).and_return(YES);
        
        NSUUID *fakeId = nice_fake_for([NSUUID class]);
        fakeId stub_method(@selector(UUIDString)).and_return(@"fakeUUID");
        fakeManager stub_method(@selector(advertisingIdentifier)).and_return(fakeId);
        
        UIDevice *fakeDevice = nice_fake_for([UIDevice class]);
        fakeDevice stub_method(@selector(systemVersion)).and_return(@"fakeOSVersion");
        fakeDevice stub_method(@selector(model)).and_return(@"fakeModel");
        [injector bind:[UIDevice class] toInstance:fakeDevice];
        
        asapService = [injector getInstance:[STRAsapService class]];
    });

    describe(@"fetching an ad", ^{
        __block STRDeferred *restClientDeferred;
        __block STRDeferred *adServiceDeferred;
        __block STRPromise *returnedPromise;
        __block STRAdPlacement *adPlacement;

        beforeEach(^{
            restClientDeferred = [STRDeferred defer];
            restClient stub_method(@selector(getAsapInfoWithParameters:)).and_return(restClientDeferred.promise);

            adPlacement = [[STRAdPlacement alloc] init];
            adPlacement.placementKey = @"placementKey";

            NSDictionary *customProperties = @{
                @"key1": @"value1",
                @"key2": @"value2"
            };
            
            adPlacement.customProperties = customProperties;
        });

        describe(@"when an ad is retrieved from the cache", ^{

            beforeEach(^{
                adCache stub_method(@selector(isAdAvailableForPlacement:AndInitializeAd:)).and_return(YES);
                adCache stub_method(@selector(fetchCachedAdForPlacement:)).and_return(ad);
                adCache stub_method(@selector(shouldBeginFetchForPlacement:)).and_return(NO);

                returnedPromise = [asapService fetchAdForPlacement:adPlacement isPrefetch:YES];
            });

            it(@"does not make a request to asap", ^{
                restClient should_not have_received(@selector(getAsapInfoWithParameters:));
            });

            it(@"returns a promise that is resolved with the cached ad", ^{
                returnedPromise.value should equal(ad);
            });
        });

        describe(@"when no ad is cached for the given placement key", ^{
            beforeEach(^{
                adCache stub_method(@selector(fetchCachedAdForPlacement:));
                adCache stub_method(@selector(isAdAvailableForPlacement:AndInitializeAd:)).and_return(NO);

                adServiceDeferred = [STRDeferred defer];
                adService stub_method(@selector(fetchAdForPlacement:isPrefetch:)).and_return(adServiceDeferred.promise);
                adService stub_method(@selector(fetchAdForPlacement:auctionParameterKey:auctionParameterValue:isPrefetch:)).and_return(adServiceDeferred.promise);

                returnedPromise = [asapService fetchAdForPlacement:adPlacement isPrefetch:YES];
            });

            it(@"makes a request to asap", ^{
                restClient should have_received(@selector(getAsapInfoWithParameters:)).with(@{
                    @"deviceId": @"fakeUUID",
                    @"doNotTrack": @"false",
                    @"language": @"en-US",
                    @"make": @"Apple",
                    @"model": @"fakeModel",
                    @"os": @"fakeOSVersion",
                    @"pkey": @"placementKey",
                    @"pubAppName": @"specs",
                    @"pubAppVersion": @"1.0",
                    @"customKeys[key1]": @"value1",
                    @"customKeys[key2]": @"value2"
                });
            });

            it(@"returns an unresolved promise", ^{
                returnedPromise should_not be_nil;
                returnedPromise.value should be_nil;
            });

            describe(@"when asap responds with with a not OK Status", ^{
                it(@"rejects the returned promise", ^{
                    NSDictionary *asapReturnValue = @{@"status": @"Your pkey was not found"};
                    [restClientDeferred resolveWithValue:asapReturnValue];

                    returnedPromise.error should_not be_nil;
                });
            });

            describe(@"when asap unsuccessfully responds", ^{
                it(@"rejects the returned promise", ^{
                    [restClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];

                    returnedPromise.error should_not be_nil;
                });
            });

            describe(@"when asap responds successfully ", ^{
                describe(@"when the key type is creative_key", ^{
                    it(@"calls the ad service with the creative key set", ^{
                        NSDictionary *asapReturnValue = @{@"status": @"OK",
                                                          @"keyType": @"creative_key",
                                                          @"keyValue": @"fake_creative_key"};
                        [restClientDeferred resolveWithValue:asapReturnValue];

                        adService should have_received(@selector(fetchAdForPlacement:auctionParameterKey:auctionParameterValue:isPrefetch:)).with(adPlacement, @"creative_key", @"fake_creative_key", YES);
                    });
                });

                describe(@"when the key type is campaign_key", ^{
                    it(@"calls the ad service with the campaign key set", ^{
                        NSDictionary *asapReturnValue = @{@"status": @"OK",
                                                          @"keyType": @"campaign_key",
                                                          @"keyValue": @"fake_campaign_key"};
                        [restClientDeferred resolveWithValue:asapReturnValue];

                        adService should have_received(@selector(fetchAdForPlacement:auctionParameterKey:auctionParameterValue:isPrefetch:)).with(adPlacement, @"campaign_key", @"fake_campaign_key", YES);
                    });
                });

                describe(@"when the key type is anything else", ^{
                    it(@"calls the ad service with no params", ^{
                        NSDictionary *asapReturnValue = @{@"status": @"OK",
                                                          @"keyType": @"some_other_key",
                                                          @"keyValue": @"something_not_used"};
                        [restClientDeferred resolveWithValue:asapReturnValue];

                        adService should have_received(@selector(fetchAdForPlacement:isPrefetch:)).with(adPlacement, YES);
                    });
                });

                describe(@"when the ad service responds successfully", ^{
                    it(@"resolves the returned promise", ^{
                        NSDictionary *asapReturnValue = @{@"status": @"OK",
                                                          @"keyType": @"some_other_key",
                                                          @"keyValue": @"something_not_used"};
                        [restClientDeferred resolveWithValue:asapReturnValue];
                        [adServiceDeferred resolveWithValue:ad];

                        returnedPromise.value should equal(ad);
                    });
                });

                describe(@"when the ad service rejects", ^{
                    it(@"rejects the returned promise", ^{
                        NSDictionary *asapReturnValue = @{@"status": @"OK",
                                                          @"keyType": @"some_other_key",
                                                          @"keyValue": @"something_not_used"};
                        [restClientDeferred resolveWithValue:asapReturnValue];
                        [adServiceDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];

                        returnedPromise.error should_not be_nil;
                    });
                });
            });
        });
    });
});

SPEC_END
