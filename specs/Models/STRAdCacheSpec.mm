#import "STRAdCache.h"
#import "STRAdvertisement.h"
#import "STRDateProvider.h"
#import "STRAdPlacement.h"
#import "STRFullAdView.h"

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

    xdescribe(@"-saveAds:forPlacement:andInitializeAtIndex:", ^{
    });

    describe(@"-fetchCachedAdForPlacement:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;
        __block STRAdPlacement *recentPlacement;
        __block STRAdPlacement *expiredPlacement;

        beforeEach(^{
            recentAd = [[STRAdvertisement alloc] init];
            recentAd.placementKey = @"pkey-recentAd";
            recentAd.creativeKey = @"ckey-recentAd";
            recentPlacement = [[STRAdPlacement alloc] init];
            recentPlacement.placementKey = @"pkey-recentAd";
            
            expiredAd = [[STRAdvertisement alloc] init];
            expiredAd.placementKey = @"pkey-expiredAd";
            expiredAd.creativeKey = @"ckey-expiredAd";
            expiredPlacement = [[STRAdPlacement alloc] init];
            expiredPlacement.placementKey = @"pkey-expiredAd";

            dateProvider stub_method(@selector(now)).and_do(^(NSInvocation * invocation) {
                NSDate *date;
                if (dateProvider.sent_messages.count == 1) {
                    date = [NSDate dateWithTimeIntervalSince1970:1000];
                } else if (dateProvider.sent_messages.count == 2) {
                    date = [NSDate dateWithTimeIntervalSince1970:10000];
                } else {
                    date = [NSDate dateWithTimeIntervalSince1970:10019];
                }

                [invocation setReturnValue:&date];
            });
            
            [cache saveAds:[NSMutableArray arrayWithArray:@[expiredAd]] forPlacement:expiredPlacement andInitializeAtIndex:YES];
            [cache saveAds:[NSMutableArray arrayWithArray:@[recentAd]] forPlacement:recentPlacement andInitializeAtIndex:YES];
        });

        it(@"returns nil if no ad exists", ^{
            STRAdPlacement *nonExistantPlacement = [[STRAdPlacement alloc] init];
            nonExistantPlacement.placementKey = @"pkey-nonexistant";
            [cache fetchCachedAdForPlacement:nonExistantPlacement] should be_nil;
        });

        it(@"returns the saved ad if the ad was fetched more than 2 minutes ago", ^{
            [cache fetchCachedAdForPlacement:expiredPlacement] should equal(expiredAd);
        });

        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForPlacement:recentPlacement] should equal(recentAd);
        });
    });

    describe(@"-fetchCachedAdForPlacementKey:CreativeKey:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;
        __block STRAdPlacement *recentPlacement;
        __block STRAdPlacement *expiredPlacement;
        
        beforeEach(^{
            recentAd = [[STRAdvertisement alloc] init];
            recentAd.placementKey = @"pkey-recentAd";
            recentAd.creativeKey = @"ckey-recentAd";
            recentPlacement = [[STRAdPlacement alloc] init];
            recentPlacement.placementKey = @"pkey-recentAd";
            
            expiredAd = [[STRAdvertisement alloc] init];
            expiredAd.placementKey = @"pkey-expiredAd";
            expiredAd.creativeKey = @"ckey-expiredAd";
            expiredPlacement = [[STRAdPlacement alloc] init];
            expiredPlacement.placementKey = @"pkey-expiredAd";
            
            dateProvider stub_method(@selector(now)).and_do(^(NSInvocation * invocation) {
                NSDate *date;
                if (dateProvider.sent_messages.count == 1) {
                    date = [NSDate dateWithTimeIntervalSince1970:1000];
                } else if (dateProvider.sent_messages.count == 2) {
                    date = [NSDate dateWithTimeIntervalSince1970:10000];
                } else {
                    date = [NSDate dateWithTimeIntervalSince1970:10019];
                }
                
                [invocation setReturnValue:&date];
            });
            
            [cache saveAds:[NSMutableArray arrayWithArray:@[expiredAd]] forPlacement:expiredPlacement andInitializeAtIndex:NO];
            [cache saveAds:[NSMutableArray arrayWithArray:@[recentAd]] forPlacement:recentPlacement andInitializeAtIndex:NO];
        });
        
        it(@"returns nil if no ad exists", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-nonexistant" CreativeKey:@"ckey-nonexistant"] should be_nil;
        });
        
        it(@"returns the saved ad if the ad was fetched more than 2 minutes ago", ^{
            [cache fetchCachedAdForPlacementKey:expiredPlacement.placementKey CreativeKey:@"ckey-expiredAd"] should equal(expiredAd);
        });
        
        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForPlacementKey:recentPlacement.placementKey CreativeKey:@"ckey-recentAd"] should equal(recentAd);
        });
    });

    describe(@"-isAdAvailableForPlacement:", ^{
        __block STRAdvertisement *recentAd;
        __block STRAdvertisement *expiredAd;
        __block STRAdPlacement *recentPlacement;
        __block STRAdPlacement *expiredPlacement;
        
        describe(@"with the default timeout", ^{
            beforeEach(^{
                recentAd = [[STRAdvertisement alloc] init];
                recentAd.placementKey = @"pkey-recentAd";
                recentAd.creativeKey = @"ckey-recentAd";
                recentAd.visibleImpressionTime = [NSDate dateWithTimeIntervalSince1970:999];
                recentPlacement = [[STRAdPlacement alloc] init];
                recentPlacement.placementKey = @"pkey-recentAd";
                recentPlacement.adView = nice_fake_for([STRFullAdView class]);
                recentPlacement.adView stub_method(@selector(percentVisible)).and_return(0.50);

                expiredAd = [[STRAdvertisement alloc] init];
                expiredAd.placementKey = @"pkey-expiredAd";
                expiredAd.creativeKey = @"ckey-expiredAd";
                expiredAd.visibleImpressionTime = [NSDate dateWithTimeIntervalSince1970:100];
                expiredPlacement = [[STRAdPlacement alloc] init];
                expiredPlacement.placementKey = @"pkey-expiredAd";

                dateProvider stub_method(@selector(now)).and_do(^(NSInvocation * invocation) {
                    NSDate *date;
                    if (dateProvider.sent_messages.count == 1) {
                        date = [NSDate dateWithTimeIntervalSince1970:1000];
                    } else if (dateProvider.sent_messages.count == 2) {
                        date = [NSDate dateWithTimeIntervalSince1970:10000];
                    } else {
                        date = [NSDate dateWithTimeIntervalSince1970:10019];
                    }

                    [invocation setReturnValue:&date];
                });
                
                [cache saveAds:[NSMutableArray arrayWithArray:@[recentAd]] forPlacement:recentPlacement andInitializeAtIndex:YES];
                [cache saveAds:[NSMutableArray arrayWithArray:@[expiredAd]] forPlacement:expiredPlacement andInitializeAtIndex:YES];
            });

            it(@"returns NO if no ad has been fetched", ^{
                STRAdPlacement *nonExistantPlacement = [[STRAdPlacement alloc] init];
                nonExistantPlacement.placementKey = @"pkey-nonexistant";
                [cache isAdAvailableForPlacement:nonExistantPlacement] should be_falsy;
            });

            it(@"returns NO if the saved ad was fetched more than 2 minutes ago", ^{
                [cache isAdAvailableForPlacement:expiredPlacement] should be_falsy;
            });

            it(@"returns YES if the ad is currently on screen", ^{
                [cache isAdAvailableForPlacement:recentPlacement] should be_truthy;
            });

            it(@"returns YES if the ad is not older than 120 seconds", ^{
                recentPlacement.adView stub_method(@selector(percentVisible)).again().and_return(0.0);
                [cache isAdAvailableForPlacement:recentPlacement] should be_truthy;
            });
        });
    });

    describe(@"-numberOfAdsAvailableForPlacement:", ^{
        __block STRAdPlacement *adPlacement;
        
        beforeEach(^{
            adPlacement = [[STRAdPlacement alloc] init];
            adPlacement.placementKey = @"pkey-fake";
        });
        
        it(@"returns the number of ads that have not been assigned", ^{
            STRAdvertisement *firstAd = [[STRAdvertisement alloc] init];
            STRAdvertisement *secondAd = [[STRAdvertisement alloc] init];
            STRAdvertisement *thirdAd = [[STRAdvertisement alloc] init];
            [cache saveAds:[NSMutableArray arrayWithArray:@[firstAd, secondAd, thirdAd]] forPlacement:adPlacement andInitializeAtIndex:NO];
            [cache numberOfAdsAvailableForPlacement:adPlacement] should equal(3);
        });
    });

    describe(@"-shouldBeginFetchForPlacement:", ^{
        __block STRAdPlacement *placement;
        beforeEach(^{
            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"fakePlacementKey";
        });

        it(@"returns YES if there are no ads cached", ^{
            [cache shouldBeginFetchForPlacement:placement.placementKey] should be_truthy;
        });

        it(@"returns YES if there is only one ad cached", ^{
            [cache saveAds:[NSMutableArray arrayWithArray:@[[NSObject new]]] forPlacement:placement andInitializeAtIndex:NO];

            [cache shouldBeginFetchForPlacement:placement.placementKey] should be_truthy;
        });

        it(@"returns NO if there are more than 1 ad available", ^{
            [cache saveAds:[NSMutableArray arrayWithArray:@[[NSObject new], [NSObject new], [NSObject new]]] forPlacement:placement andInitializeAtIndex:NO];
 
            [cache shouldBeginFetchForPlacement:placement.placementKey] should be_falsy;
        });

        it(@"returns NO if there is a pending ad request", ^{
            [cache pendingAdRequestInProgressForPlacement:placement.placementKey];

            [cache shouldBeginFetchForPlacement:placement.placementKey] should be_falsy;

            [cache clearPendingAdRequestForPlacement:placement.placementKey];
        });
    });

    describe(@"-pendingAdRequestInProgressforPlacement:", ^{
        it(@"returns NO if no request pending", ^{
            [cache pendingAdRequestInProgressForPlacement:@"fakePlacementKey"] should be_falsy;
        });

        it(@"returns YES if a pending request was added", ^{
            [cache pendingAdRequestInProgressForPlacement:@"fakePlacementKey"] should be_falsy;
            [cache pendingAdRequestInProgressForPlacement:@"fakePlacementKey"] should be_truthy;
        });

        it(@"returns NO if the pending request was cleared", ^{
            [cache pendingAdRequestInProgressForPlacement:@"fakePlacementKey"] should be_falsy;
            [cache clearPendingAdRequestForPlacement:@"fakePlacementKey"];
            [cache pendingAdRequestInProgressForPlacement:@"fakePlacementKey"] should be_falsy;
        });
    });

    /*
     MMM - Not much value in testing getters and setters
    xdescribe(@"-clearPendingAdRequestForPlacement:", ^{
    });

    xdescribe(@"-getInfiniteScrollFieldsForPlacement:", ^{
    });

    xdescribe(@"-saveInfiniteScrollFields:", ^{
    });
     */
});

SPEC_END
