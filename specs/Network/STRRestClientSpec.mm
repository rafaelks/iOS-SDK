#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDeferred.h"
#import "STRInjector.h"
#import "STRAppModule.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRRestClientSpec)

describe(@"STRRestClient", ^{
    __block STRRestClient *client;
    __block STRNetworkClient<CedarDouble> *networkClient;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        networkClient = nice_fake_for([STRNetworkClient class]);
        [injector bind:[STRNetworkClient class] toInstance:networkClient];

        client = [injector getInstance:[STRRestClient class]];
    });

    NSURLRequest *(^mostRecentRequest)(void) = ^NSURLRequest * {
        networkClient should have_received(@selector(get:));

        __autoreleasing NSMutableURLRequest *request;
        [[networkClient.sent_messages firstObject] getArgument:&request atIndex:2];
        return request;
    };

    it(@"uses the production endpoint", ^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];
        [injector bind:[STRNetworkClient class] toInstance:networkClient];
        client = [injector getInstance:[STRRestClient class]];

        [client getWithParameters:@{}];

        mostRecentRequest().URL.host should equal(@"btlr.sharethrough.com");
    });

    describe(@"-getWithParameters:", ^{
        __block STRDeferred *deferred;

        beforeEach(^{
            deferred = [STRDeferred defer];
            networkClient stub_method(@selector(get:)).and_return(deferred.promise);
        });

        it(@"encodes the query parameters", ^{
            [client getWithParameters:@{@"foo": @"bar", @"key": @"fakeKey123"}];

            mostRecentRequest().URL.query should equal(@"foo=bar&key=fakeKey123");
        });

        it(@"returns an unresolved promise", ^{
            STRPromise *promise = [client getWithParameters:nil];

            promise should_not be_nil;
            promise.value should be_nil;
        });

        describe(@"when the network client resolves successfully", ^{
            it(@"resolves the promise with the JSON parsed", ^{
                STRPromise *promise = [client getWithParameters:nil];
                NSDictionary *expectedJSON = @{@"hello": @"from a server"};
                [deferred resolveWithValue:[NSJSONSerialization dataWithJSONObject:expectedJSON options:0 error:nil]];

                promise.value should equal(expectedJSON);
            });

            it(@"rejects the promise if JSON fails to parse", ^{
                STRPromise *promise = [client getWithParameters:nil];
                [deferred resolveWithValue:[NSData data]];

                promise.error should_not be_nil;
            });
        });

        describe(@"when the network client resolves unsuccessfully", ^{
            it(@"rejects the promise", ^{
                STRPromise *promise = [client getWithParameters:nil];
                NSError *error = [NSError errorWithDomain:@"Error domain" code:0 userInfo:nil];
                [deferred rejectWithError:error];

                promise.error should be_same_instance_as(error);
            });
        });
    });

    describe(@"-getDFPPathForPlacement:", ^{
        __block STRDeferred *deferred;

        beforeEach(^{
            deferred = [STRDeferred defer];
            networkClient stub_method(@selector(get:)).and_return(deferred.promise);
        });

        describe(@"when the network client resolves successfully", ^{
            it(@"resolves the promise with the JSON parsed", ^{
                STRPromise *promise = [client getDFPPathForPlacement:@"abc123"];
                NSDictionary *expectedJSON = @{@"dfp_path": @"/123/test/path"};
                [deferred resolveWithValue:[NSJSONSerialization dataWithJSONObject:expectedJSON options:0 error:nil]];

                promise.value should equal(@"/123/test/path");
            });

            it(@"rejects the promise if JSON fails to parse", ^{
                STRPromise *promise = [client getDFPPathForPlacement:@"abc123"];
                [deferred resolveWithValue:[NSData data]];

                promise.error should_not be_nil;
            });

            it(@"rejects the promise if the dfp_path is blank", ^{
                STRPromise *promise = [client getDFPPathForPlacement:@"abc123"];
                NSDictionary *expectedJSON = @{@"dfp_path": [NSNull null]};
                [deferred resolveWithValue:[NSJSONSerialization dataWithJSONObject:expectedJSON options:0 error:nil]];

                promise.error should_not be_nil;
            });
        });

        describe(@"when the network client resolves unsuccessfully", ^{
            it(@"rejects the promise", ^{
                STRPromise *promise = [client getDFPPathForPlacement:@"abc123"];
                NSError *error = [NSError errorWithDomain:@"Error domain" code:0 userInfo:nil];
                [deferred rejectWithError:error];

                promise.error should be_same_instance_as(error);
            });
        });
    });

    describe(@"-sendBeaconWithParameters:", ^{
        beforeEach(^{
            networkClient stub_method(@selector(get:));
            [client sendBeaconWithParameters:@{@"foo": @"bar", @"key": @"fakeKey123"}];
        });

        it(@"encodes the query parameters", ^{
            mostRecentRequest().URL.query should equal(@"foo=bar&key=fakeKey123");
        });

        it(@"uses the beacons endpoint", ^{
            NSURL *requestURL = mostRecentRequest().URL;
            requestURL.host should equal(@"b.sharethrough.com");
            requestURL.lastPathComponent should equal(@"butler");

        });
    });

    describe(@"-sendBeaconWithURL:", ^{
        __block NSURL *beaconURL;

        beforeEach(^{
            networkClient stub_method(@selector(get:));
            beaconURL = [NSURL URLWithString:@"http://fake.com?timestamp=1234"];
        });

        it(@"should send a get message to the network client", ^{
            [client sendBeaconWithURL:beaconURL];
            mostRecentRequest().URL.absoluteString should equal(@"http://fake.com?timestamp=1234");
        });
    });

});

SPEC_END
