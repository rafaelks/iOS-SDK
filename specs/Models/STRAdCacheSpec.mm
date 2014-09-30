#import "STRAdCache.h"
#import "STRAdvertisement.h"
#import "STRDateProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdCacheSpec)

describe(@"STRAdCache", ^{
    __block STRAdCache *cache;
    __block STRDateProvider<CedarDouble> *dateProvider;

    beforeEach(^{
        dateProvider = nice_fake_for([STRDateProvider class]);

        cache = [[STRAdCache alloc] initWithDateProvider:dateProvider];
    });
    
    describe(@"-setAdCacheTimeoutInSeconds", ^{
        describe(@"when the value is >= 20", ^{
            it(@"returns the set value", ^{
                [cache setAdCacheTimeoutInSeconds:20] should equal(20);
                [cache setAdCacheTimeoutInSeconds:NSUIntegerMax] should equal(NSUIntegerMax);
            });
        });
        
        describe(@"when the value is < 20", ^{
            it(@"returns the set value", ^{
                [cache setAdCacheTimeoutInSeconds:19] should equal(20);
                [cache setAdCacheTimeoutInSeconds:0] should equal(20);
            });
        });
    });

    describe(@"-fetchCachedAdForPlacementKey:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;

        beforeEach(^{
            recentAd = [[STRAdvertisement alloc] init];
            recentAd.placementKey = @"pkey-recentAd";
            recentAd.creativeKey = @"ckey-recentAd";
            
            expiredAd = [[STRAdvertisement alloc] init];
            expiredAd.placementKey = @"pkey-expiredAd";
            expiredAd.creativeKey = @"ckey-expiredAd";

            dateProvider stub_method(@selector(now)).and_do(^(NSInvocation * invocation) {
                NSDate *date;
                if (dateProvider.sent_messages.count == 1) {
                    date = [NSDate dateWithTimeIntervalSince1970:1000];
                } else if (dateProvider.sent_messages.count == 2) {
                    date = [NSDate dateWithTimeIntervalSince1970:10000];
                } else {
                    date = [NSDate dateWithTimeIntervalSince1970:10119];
                }

                [invocation setReturnValue:&date];
            });

            [cache saveAd:expiredAd];
            [cache saveAd:recentAd];
        });

        it(@"returns nil if no ad exists", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-nonexistant"] should be_nil;
        });

        it(@"returns the saved ad if the ad was fetched more than 2 minutes ago", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-expiredAd"] should equal(expiredAd);
        });

        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-recentAd"] should equal(recentAd);
        });
    });
    
    describe(@"-fetchCachedAdForCreativeKey:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;
        
        beforeEach(^{
            recentAd = [[STRAdvertisement alloc] init];
            recentAd.placementKey = @"pkey-recentAd";
            recentAd.creativeKey = @"ckey-recentAd";
            
            expiredAd = [[STRAdvertisement alloc] init];
            expiredAd.placementKey = @"pkey-expiredAd";
            expiredAd.creativeKey = @"ckey-expiredAd";
            
            dateProvider stub_method(@selector(now)).and_do(^(NSInvocation * invocation) {
                NSDate *date;
                if (dateProvider.sent_messages.count == 1) {
                    date = [NSDate dateWithTimeIntervalSince1970:1000];
                } else if (dateProvider.sent_messages.count == 2) {
                    date = [NSDate dateWithTimeIntervalSince1970:10000];
                } else {
                    date = [NSDate dateWithTimeIntervalSince1970:10119];
                }
                
                [invocation setReturnValue:&date];
            });
            
            [cache saveAd:expiredAd];
            [cache saveAd:recentAd];
        });
        
        it(@"returns nil if no ad exists", ^{
            [cache fetchCachedAdForCreativeKey:@"ckey-nonexistant"] should be_nil;
        });
        
        it(@"returns the saved ad if the ad was fetched more than 2 minutes ago", ^{
            [cache fetchCachedAdForCreativeKey:@"ckey-expiredAd"] should equal(expiredAd);
        });
        
        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForCreativeKey:@"ckey-recentAd"] should equal(recentAd);
        });
    });

    describe(@"-isAdStale:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;

        beforeEach(^{
            recentAd = [[STRAdvertisement alloc] init];
            recentAd.placementKey = @"pkey-recentAd";
            recentAd.creativeKey = @"ckey-recentAd";

            expiredAd = [[STRAdvertisement alloc] init];
            expiredAd.placementKey = @"pkey-expiredAd";
            expiredAd.creativeKey = @"ckey-expiredAd";

            dateProvider stub_method(@selector(now)).and_do(^(NSInvocation * invocation) {
                NSDate *date;
                if (dateProvider.sent_messages.count == 1) {
                    date = [NSDate dateWithTimeIntervalSince1970:1000];
                } else if (dateProvider.sent_messages.count == 2) {
                    date = [NSDate dateWithTimeIntervalSince1970:10000];
                } else {
                    date = [NSDate dateWithTimeIntervalSince1970:10119];
                }

                [invocation setReturnValue:&date];
            });

            [cache saveAd:expiredAd];
            [cache saveAd:recentAd];
        });

        it(@"returns YES if no ad has been fetched", ^{
            [cache isAdStale:@"pkey-nonexistant"] should be_truthy;
        });

        it(@"returns YES if the saved ad was fetched more than 2 minutes ago", ^{
            [cache isAdStale:@"pkey-expiredAd"] should be_truthy;
        });

        it(@"returns NO if the ad is not older than 120 seconds", ^{
            [cache isAdStale:@"pkey-recentAd"] should be_falsy;
        });
    });
});

SPEC_END
