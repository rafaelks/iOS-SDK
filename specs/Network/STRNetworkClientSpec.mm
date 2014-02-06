#import "STRNetworkClient.h"

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

SPEC_BEGIN(STRNetworkClientSpec)

describe(@"STRNetworkClient", ^{
    __block STRNetworkClient *client;
    __block NSURLRequest *request;

    beforeEach(^{
        client = [STRNetworkClient new];
        request = [NSURLRequest requestWithURL:[NSURL URLWithString:@""]];
    });

    it(@"uses the main queue for the request", ^{
        [client get:request];
        recentQueue should be_same_instance_as([NSOperationQueue mainQueue]);
    });

    it(@"returns an unresolved promise", ^{
        STRPromise *promise = [client get:request];

        promise should_not be_nil;
        promise.value should be_nil;
    });

    it(@"makes a request using the request passed in", ^{
        [client get:request];

        recentRequest.URL should equal(request.URL);
    });

    describe(@"the user agent", ^{
        __block UIDevice *currentDevice;

        beforeEach(^{
            currentDevice = [UIDevice currentDevice];
            spy_on(currentDevice);
        });

        context(@"iPod", ^{
            beforeEach(^{
                currentDevice stub_method(@selector(model)).and_return(@"iPod touch");
                [client get:request];
            });

            it(@"has a useful user agent that will be recognized by the ad server", ^{
                [recentRequest valueForHTTPHeaderField:@"User-Agent"] should contain(@"iPod");
                [recentRequest valueForHTTPHeaderField:@"User-Agent"] should contain(@"iPhone");
            });
        });

        context(@"iPad", ^{
            beforeEach(^{
                currentDevice stub_method(@selector(model)).and_return(@"iPad");
                [client get:request];
            });

            it(@"has a useful user agent that will be recognized by the ad server", ^{
                [recentRequest valueForHTTPHeaderField:@"User-Agent"] should contain(@"iPad; OS like Mac OS X");
            });
        });

        context(@"iPhone", ^{
            beforeEach(^{
                currentDevice stub_method(@selector(model)).and_return(@"iPhone");
                [client get:request];
            });

            it(@"has a useful user agent that will be recognized by the ad server", ^{
                [recentRequest valueForHTTPHeaderField:@"User-Agent"] should contain(@"iPhone");
                [recentRequest valueForHTTPHeaderField:@"User-Agent"] should_not contain(@"iPod");
            });
        });
    });

    describe(@"when the async request completes", ^{
        it(@"resolves the promise", ^{
            STRPromise *promise = [client get:request];
            NSData *expectedData = [NSData data];
            recentHandler(nil, expectedData,nil);

            promise.value should be_same_instance_as(expectedData);
        });
    });

    describe(@"when the async error has a connection error", ^{
        it(@"rejects the promise with that error", ^{
            STRPromise *promise = [client get:request];
            NSError *expectedError = [NSError errorWithDomain:@"Error!!!" code:310 userInfo:nil];
            recentHandler(nil, nil, expectedError);

            promise.error should equal(expectedError);
        });
    });
});

SPEC_END
