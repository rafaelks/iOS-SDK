#import "STRGridlikeViewDataSourceProxy.h"

#import "STRAdCache.h"
#import "STRAdGenerator.h"
#import "STRAdPlacement.h"
#import "STRAdPlacementAdjuster.h"
#import "STRAppModule.h"
#import "STRFakeAdGenerator.h"
#import "STRInjector.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRGridlikeViewDataSourceProxySpec)

describe(@"STRGridlikeViewDataSourceProxy", ^{
    __block STRGridlikeViewDataSourceProxy *proxy;
    __block UIViewController *presentingViewController;
    __block STRInjector *injector;
    __block STRAdGenerator *adGenerator;
    __block id originalDataSource;
    __block STRAdPlacementAdjuster *adjuster;
    __block NSString *fakePlacementKey;
    __block STRAdCache *fakeAdCache;

    beforeEach(^{
        fakePlacementKey = @"fake-placement-key";
        fakeAdCache = nice_fake_for([STRAdCache class]);
        adjuster = [STRAdPlacementAdjuster adjusterInSection:0 placementKey:fakePlacementKey adCache:fakeAdCache];

        injector = [STRInjector injectorForModule:[STRAppModule new]];
        adGenerator = [STRFakeAdGenerator new];
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        presentingViewController = nice_fake_for([UIViewController class]);

        originalDataSource = nice_fake_for(@protocol(UITableViewDataSource));

    });


    describe(@"datasource procotol conform", ^{
        it(@"allows a UICollectionViewDataSource", ^{
            id dataSource = nice_fake_for(@protocol(UICollectionViewDataSource));

            expect(^{
                proxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:nil
                                                                                    adPlacement:nil
                                                                                     injector:nil];
                proxy.originalDataSource = dataSource;
            }).to_not(raise_exception);

            proxy.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"allows a UITableViewDataSource", ^{
            id dataSource = nice_fake_for(@protocol(UITableViewDataSource));

            expect(^{
                proxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:nil
                                                                                    adPlacement:nil
                                                                                     injector:nil];
                proxy.originalDataSource = dataSource;
            }).to_not(raise_exception);

            proxy.originalDataSource should be_same_instance_as(dataSource);

        });

        it(@"allows a data source that conforms to UITableView and UICollectionView's protocols", ^{
            id dataSource = nice_fake_for(@protocol(UITableViewDataSource), @protocol(UICollectionViewDataSource));
            dataSource stub_method(@selector(tableView:numberOfRowsInSection:)).and_return((long)1);
            dataSource stub_method(@selector(collectionView:numberOfItemsInSection:)).and_return((long)2);

            expect(^{
                proxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:nil
                                                                                    adPlacement:nil
                                                                                     injector:nil];
                proxy.originalDataSource = dataSource;
            }).to_not(raise_exception);

            proxy.originalDataSource should be_same_instance_as(dataSource);
            [proxy tableView:nil numberOfRowsInSection:0];
            [proxy collectionView:nil numberOfItemsInSection:0];

            dataSource should have_received(@selector(collectionView:numberOfItemsInSection:));
            dataSource should have_received(@selector(tableView:numberOfRowsInSection:));
        });

        it(@"allows a nil data source", ^{
            expect(^{
                proxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:nil
                                                                                    adPlacement:nil
                                                                                     injector:nil];
            }).to_not(raise_exception);

            proxy.originalDataSource should be_nil;
        });

        it(@"raises an exception when data source is not nil and does not conform to known protocol", ^{
            id dataSource = @"Hello!";

            expect(^{
                proxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:nil
                                                                                    adPlacement:nil
                                                                                     injector:nil];
                proxy.originalDataSource = dataSource;
            }).to(raise_exception);

            proxy.originalDataSource should_not be_same_instance_as(dataSource);

        });
    });

    describe(@"-copyWithNewDataSource:", ^{
        __block STRAdPlacement *fakePlacement;
        beforeEach(^{
            fakePlacement = nice_fake_for([STRAdPlacement class]);
            proxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"adCell"
                                                                                adPlacement:fakePlacement
                                                                                 injector:injector];
            proxy.originalDataSource = originalDataSource;
        });

        it(@"returns a new delegateProxy with a different data source", ^{
            id <UITableViewDataSource> newDataSource = nice_fake_for(@protocol(UITableViewDataSource));

            STRGridlikeViewDataSourceProxy *newProxy = [proxy copyWithNewDataSource:newDataSource];
            newProxy should_not be_same_instance_as(proxy);
            newProxy.originalDataSource should be_same_instance_as(newDataSource);
            newProxy.adCellReuseIdentifier should equal(@"adCell");
            newProxy.placement should be_same_instance_as(fakePlacement);
            newProxy.injector should be_same_instance_as(injector);
        });
    });

});

SPEC_END
