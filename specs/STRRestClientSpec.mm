#import "STRRestClient.h"
#import "STRPromise.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@implementation NSURLConnection (SpecHelper)

static NSURLRequest *recentRequest;
static NSOperationQueue *recentQueue;
static void (^recentHandler)(NSURLResponse*, NSData*, NSError*);

+ (void)sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler {
    recentRequest = request;
    recentQueue = queue;
    recentHandler = handler;
}

@end

SPEC_BEGIN(STRRestClientSpec)

describe(@"STRRestClient", ^{
    __block STRRestClient *client;

    beforeEach(^{
        client = [[STRRestClient alloc] initWithStaging:NO];
    });

    describe(@"when pointed to the staging server", ^{
        it(@"uses the staging endpoint", ^{
            client = [[STRRestClient alloc] initWithStaging:YES];
            [client getWithParameters:@{}];

            recentRequest.URL.host should equal(@"btlr-staging.sharethrough.com");
        });
    });

    describe(@"when pointed to the production server", ^{
        it(@"uses the production endpoint", ^{
            client = [[STRRestClient alloc] initWithStaging:NO];
            [client getWithParameters:@{}];

            recentRequest.URL.host should equal(@"btlr.sharethrough.com");
        });
    });

    describe(@"getWithParameters", ^{
        it(@"encodes the query parameters", ^{
            [client getWithParameters:@{@"foo": @"bar", @"key": @"fakeKey123"}];

            recentRequest.URL.query should equal(@"foo=bar&key=fakeKey123");
        });

        it(@"sets the User-Agent to pretend to be an iPhone (hack for server)", ^{
            [client getWithParameters:@{}];

            [recentRequest valueForHTTPHeaderField:@"User-Agent"] should equal(@"iPhone");
        });

        it(@"uses the main queue for the request", ^{
            [client getWithParameters:@{}];
            recentQueue should be_same_instance_as([NSOperationQueue mainQueue]);
        });

        it(@"returns an unresolved promise", ^{
            STRPromise *promise = [client getWithParameters:nil];

            promise should_not be_nil;
            promise.value should be_nil;
        });

        describe(@"when the async request resolves successfully", ^{
            it(@"resolves the promise with the JSON parsed", ^{
                STRPromise *promise = [client getWithParameters:nil];
                NSDictionary *expectedJSON = @{@"hello": @"from a server"};
                recentHandler(nil, [NSJSONSerialization dataWithJSONObject:expectedJSON options:0 error:nil], nil);

                promise.value should equal(expectedJSON);
            });

            it(@"rejects the promise if JSON fails to parse", ^{
                STRPromise *promise = [client getWithParameters:nil];
                recentHandler(nil, [NSData data], nil);

                promise.error should_not be_nil;
            });
        });

        describe(@"when the async error has a connection error", ^{
            it(@"rejects the promise with that error", ^{
                STRPromise *promise = [client getWithParameters:nil];
                NSData *json = [NSJSONSerialization dataWithJSONObject:@{@"hello": @"from a server"} options:0 error:nil];
                NSError *expectedError = [NSError errorWithDomain:@"Error!!!" code:310 userInfo:nil];
                recentHandler(nil, json, expectedError);

                promise.error should equal(expectedError);
            });
        });
    });
});

SPEC_END
