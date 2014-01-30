#import "STRAdService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInjector.h"
#import "STRAppModule.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdServiceSpec)

describe(@"STRAdService", ^{
    __block STRAdService *service;
    __block STRRestClient *restClient;
    __block STRNetworkClient *networkClient;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule moduleWithStaging:NO]];

        restClient = nice_fake_for([STRRestClient class]);
        [injector bind:[STRRestClient class] toInstance:restClient];

        networkClient = nice_fake_for([STRNetworkClient class]);
        [injector bind:[STRNetworkClient class] toInstance:networkClient];

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

            returnedPromise = [service fetchAdForPlacementKey:@"placementKey"];
        });

        it(@"makes a request to the ad server", ^{
            restClient should have_received(@selector(getWithParameters:)).with(@{@"placement_key": @"placementKey"});
        });

        it(@"returns an unresolved promise", ^{
            returnedPromise should_not be_nil;
            returnedPromise.value should be_nil;
        });

        describe(@"when the ad server successfully responds", ^{
            beforeEach(^{
                [restClientDeferred resolveWithValue:@{
                                                       @"description": @"Dogs this smart deserve a home.",
                                                       @"thumbnail_url": @"http://i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg",
                                                       @"title": @"Meet Porter. He's a Dog.",
                                                       @"advertiser": @"Brand X",
                                                       @"media_url": @"http://www.youtube.com/watch?v=BWAK0J8Uhzk",
                                                       @"share_url": @"http://bit.ly/14hfvXG",
                                                       @"creative_key": @"imagination",
                                                       @"variant_key": @"variation"
                                                       }];
            });

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

                it(@"resolves the returned promise with an advertisement", ^{
                    returnedPromise.value should_not be_nil;
                    returnedPromise.value should be_instance_of([STRAdvertisement class]);

                    STRAdvertisement *ad = (STRAdvertisement *) returnedPromise.value;
                    ad.advertiser should equal(@"Brand X");
                    ad.title should equal(@"Meet Porter. He's a Dog.");
                    ad.adDescription should equal(@"Dogs this smart deserve a home.");
                    [ad.mediaURL absoluteString] should equal(@"http://www.youtube.com/watch?v=BWAK0J8Uhzk");
                    [ad.shareURL absoluteString] should equal(@"http://bit.ly/14hfvXG");
                    ad.creativeKey should equal(@"imagination");
                    ad.variantKey should equal(@"variation");
                    ad.placementKey should equal(@"placementKey");
                    UIImagePNGRepresentation(ad.thumbnailImage) should equal(UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]));
                });
            });

            describe(@"when the image can't be loaded", ^{
                it(@"rejects the returned promise", ^{
                    [networkClientDeferred rejectWithError:[NSError errorWithDomain:@"Error eek!" code:109 userInfo:nil]];

                    returnedPromise.error should_not be_nil;
                });
            });
        });

        describe(@"when the ad server responds without a protocol", ^{
            beforeEach(^{
                [restClientDeferred resolveWithValue:@{
                                                       @"thumbnail_url": @"//i1.ytimg.com/vi/BWAK0J8Uhzk/hqdefault.jpg",
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

SPEC_END
