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

    describe(@"-fetchCachedAdForPlacementKey:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;

        beforeEach(^{
            recentAd = [[STRAdvertisement alloc] init];
            recentAd.placementKey = @"pkey-recentAd";
            expiredAd = [[STRAdvertisement alloc] init];
            expiredAd.placementKey = @"pkey-expiredAd";

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

        it(@"returns nil if the ad was fetched more than 2 minutes ago", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-expiredAd"] should be_nil;
        });

        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-recentAd"] should equal(recentAd);
        });
    });
});

SPEC_END
