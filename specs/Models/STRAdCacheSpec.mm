#import "STRAdCache.h"
#import "STRAdvertisement.h"
#import "STRDateProvider.h"
#import "STRAdPlacement.h"
#import "STRFullAdView.h"
#import "UIView+Visible.h"

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

    describe(@"-saveAds:forPlacement:andAssignAds:", ^{
        __block NSMutableArray *creatives;
        __block STRAdvertisement *creative;
        __block STRAdPlacement *placement;

        beforeEach(^{
            creative = [[STRAdvertisement alloc] init];
            creative.creativeKey = @"ckey-fake";
            creative.placementKey = @"pkey-fake";

            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"pkey-fake";
            placement.adIndex = 0;

            creatives = [[NSMutableArray alloc] initWithArray:@[creative]];
        });

        describe(@"when initializing at the placement index", ^{
            it(@"has an ad ready for the placement index that cached it", ^{
                [cache saveAds:creatives forPlacement:placement andAssignAds:YES];
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_truthy;
            });

            it(@"does not have an ad for a different placement index", ^{
                [cache saveAds:creatives forPlacement:placement andAssignAds:YES];
                placement.adIndex = 2;
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_falsy;
            });
        });

        describe(@"when not initializing at the placement index", ^{
            it(@"has an ad ready for the placement index that cached it", ^{
                [cache saveAds:creatives forPlacement:placement andAssignAds:NO];
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_truthy;
            });

            it(@"has an ad for a different placement index", ^{
                [cache saveAds:creatives forPlacement:placement andAssignAds:NO];
                placement.adIndex = 2;
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_truthy;
            });
        });
    });

    describe(@"-fetchCachedAdForPlacement:", ^{
        __block STRAdvertisement *ad;
        __block STRAdPlacement *placement;

        beforeEach(^{
            ad = [[STRAdvertisement alloc] init];
            ad.placementKey = @"pkey-recentAd";
            ad.creativeKey = @"ckey-recentAd";
            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"pkey-recentAd";

            [cache saveAds:[NSMutableArray arrayWithArray:@[ad]] forPlacement:placement andAssignAds:YES];
        });

        it(@"returns nil if no ad exists", ^{
            STRAdPlacement *nonExistantPlacement = [[STRAdPlacement alloc] init];
            nonExistantPlacement.placementKey = @"pkey-nonexistant";
            [cache fetchCachedAdForPlacement:nonExistantPlacement] should be_nil;
        });

        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForPlacement:placement] should equal(ad);
        });
    });

    describe(@"-fetchCachedAdForPlacementKey:CreativeKey:", ^{
        __block STRAdvertisement *ad;
        __block STRAdPlacement *placement;

        beforeEach(^{
            ad = [[STRAdvertisement alloc] init];
            ad.placementKey = @"pkey-recentAd";
            ad.creativeKey = @"ckey-recentAd";
            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"pkey-recentAd";

            [cache saveAds:[NSMutableArray arrayWithArray:@[ad]] forPlacement:placement andAssignAds:NO];
        });

        it(@"returns nil if no ad exists", ^{
            [cache fetchCachedAdForPlacementKey:@"pkey-nonexistant" CreativeKey:@"ckey-nonexistant"] should be_nil;
        });

        it(@"returns the ad when it exists", ^{
            [cache fetchCachedAdForPlacementKey:placement.placementKey CreativeKey:@"ckey-recentAd"] should equal(ad);
        });
    });

    describe(@"-isAdAvailableForPlacement:", ^{
        __block STRAdvertisement *ad;
        __block STRAdPlacement *placement;

        describe(@"with the default timeout", ^{
            beforeEach(^{
                ad = [[STRAdvertisement alloc] init];
                ad.placementKey = @"pkey-recentAd";
                ad.creativeKey = @"ckey-recentAd";
                ad.visibleImpressionTime = [NSDate dateWithTimeIntervalSince1970:999];
                placement = [[STRAdPlacement alloc] init];
                placement.placementKey = @"pkey-recentAd";
                placement.adView = nice_fake_for([STRFullAdView class]);
                placement.adView stub_method(@selector(percentVisible)).and_return(0.50);

                [cache saveAds:[NSMutableArray arrayWithArray:@[ad]] forPlacement:placement andAssignAds:YES];
            });

            it(@"returns NO if no ad has been fetched", ^{
                STRAdPlacement *nonExistantPlacement = [[STRAdPlacement alloc] init];
                nonExistantPlacement.placementKey = @"pkey-nonexistant";
                [cache isAdAvailableForPlacement:nonExistantPlacement AndInitializeAd:YES] should be_falsy;
            });

            it(@"returns YES if the ad is currently on screen", ^{
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_truthy;
            });

            it(@"doesn't blow up if the adView is nil", ^{
                placement.adView = nil;
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_truthy;
            });
        });
    });

    describe(@"-numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey", ^{
        __block STRAdPlacement *placement;
        __block STRAdvertisement *cachedAd1, *cachedAd2, *assignedAd1, *assignedAd2;

        beforeEach(^{
            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"fakePlacementKey";
            cachedAd1 = [[STRAdvertisement alloc] init];
            cachedAd2 = [[STRAdvertisement alloc] init];
            assignedAd1 = [[STRAdvertisement alloc] init];
            assignedAd2 = [[STRAdvertisement alloc] init];

            [cache saveAds:[@[assignedAd1, assignedAd2, cachedAd1, cachedAd2] mutableCopy] forPlacement:placement andAssignAds:NO];
        });

        describe(@"when no ads are assigned", ^{
            it(@"returns the count of the cached ads", ^{
                [cache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:@"fakePlacementKey"] should equal(4);
            });
        });

        describe(@"when ads are assigned", ^{
            beforeEach(^{
                placement.adIndex = 0;
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES] should be_truthy;
            });

            it(@"returns the sum of assigned and queued", ^{
                [cache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:@"fakePlacementKey"] should equal(4);
            });
        });
    });

    describe(@"-numberOfUnassignedAdsInQueueForPlacementKey", ^{
        __block STRAdPlacement *placement;
        __block STRAdvertisement *cachedAd1, *cachedAd2, *assignedAd1, *assignedAd2;

        beforeEach(^{
            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"fakePlacementKey";
            cachedAd1 = [[STRAdvertisement alloc] init];
            cachedAd2 = [[STRAdvertisement alloc] init];
            assignedAd1 = [[STRAdvertisement alloc] init];
            assignedAd2 = [[STRAdvertisement alloc] init];

            [cache saveAds:[@[assignedAd1, assignedAd2, cachedAd1, cachedAd2] mutableCopy] forPlacement:placement andAssignAds:NO];
        });

        describe(@"when no ads are assigned", ^{
            it(@"returns the number of ads cached", ^{
                [cache numberOfUnassignedAdsInQueueForPlacementKey:placement.placementKey] should equal(4);
            });
        });

        describe(@"when some ads are assigned", ^{
            beforeEach(^{
                placement.adIndex = 0;
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES];
            });

            it(@"returns the number of unassigned ads", ^{
                [cache numberOfUnassignedAdsInQueueForPlacementKey:placement.placementKey] should equal(3);
            });
        });
    });

    describe(@"-clearCachedAdsForPlacement", ^{
        __block STRAdPlacement *placement;
        __block STRAdvertisement *cachedAd1, *cachedAd2, *assignedAd1, *assignedAd2;

        beforeEach(^{
            placement = [[STRAdPlacement alloc] init];
            placement.placementKey = @"fakePlacementKey";
            cachedAd1 = [[STRAdvertisement alloc] init];
            cachedAd2 = [[STRAdvertisement alloc] init];
            assignedAd1 = [[STRAdvertisement alloc] init];
            assignedAd2 = [[STRAdvertisement alloc] init];

            [cache saveAds:[@[assignedAd1, assignedAd2, cachedAd1, cachedAd2] mutableCopy] forPlacement:placement andAssignAds:NO];
        });

        describe(@"when no ads are assigned", ^{
            it(@"has no effect", ^{
                [cache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:placement.placementKey] should equal(4);
                [cache clearAssignedAdsForPlacement:placement.placementKey];
                [cache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:placement.placementKey] should equal(4);
            });
        });

        describe(@"when ads are assigned", ^{
            beforeEach(^{
                placement.adIndex = 0;
                [cache isAdAvailableForPlacement:placement AndInitializeAd:YES];
            });

            it(@"removes all the assigned ads", ^{
                [cache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:placement.placementKey] should equal(4);
                [cache clearAssignedAdsForPlacement:placement.placementKey];
                [cache numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:placement.placementKey] should equal(3);
            });
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
            [cache saveAds:[NSMutableArray arrayWithArray:@[[NSObject new]]] forPlacement:placement andAssignAds:NO];

            [cache shouldBeginFetchForPlacement:placement.placementKey] should be_truthy;
        });

        it(@"returns NO if there are more than 1 ad available", ^{
            [cache saveAds:[NSMutableArray arrayWithArray:@[[NSObject new], [NSObject new], [NSObject new]]] forPlacement:placement andAssignAds:NO];

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
