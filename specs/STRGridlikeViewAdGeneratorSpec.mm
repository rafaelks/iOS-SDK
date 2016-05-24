#import "STRGridlikeViewAdGenerator.h"
#import "STRGridlikeViewDataSourceProxy.h"
#import <objc/runtime.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const STRGridlikeViewAdGeneratorKey;

SPEC_BEGIN(STRGridlikeViewAdGeneratorSpec)

describe(@"STRGridlikeViewAdGenerator", ^{
    __block STRGridlikeViewAdGenerator *generator;
    __block UIView *view;

    beforeEach(^{
        generator = [[STRGridlikeViewAdGenerator alloc] initWithInjector:nil];
    });

    describe(@"-placeAdInGridlikeView:adCellReuseIdentifier...", ^{
        it(@"allows a UITableView", ^{
            view = [UITableView new];

            expect(^{
                [generator placeAdInGridlikeView:view
                                 dataSourceProxy:nil
                           adCellReuseIdentifier:nil
                                    placementKey:nil
                        presentingViewController:nil
                                          adSize:CGSizeZero
                                       adSection:0];
            }).to_not(raise_exception);

            objc_getAssociatedObject(view, STRGridlikeViewAdGeneratorKey) should be_same_instance_as(generator);
        });

        it(@"allows a UICollectionView", ^{
            view = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                      collectionViewLayout:[UICollectionViewFlowLayout new]];
            expect(^{
                [generator placeAdInGridlikeView:view
                                 dataSourceProxy:nil
                           adCellReuseIdentifier:nil
                                    placementKey:nil
                        presentingViewController:nil
                                          adSize:CGSizeZero
                                       adSection:0];
            }).to_not(raise_exception);

            objc_getAssociatedObject(view, STRGridlikeViewAdGeneratorKey) should be_same_instance_as(generator);

        });

        it(@"raises an exception if 'gridlikeView' is not a UICollectionView or UITableView ", ^{
            view = [UIView new];
            expect(^{
                [generator placeAdInGridlikeView:view
                                 dataSourceProxy:nil
                           adCellReuseIdentifier:nil
                                    placementKey:nil
                        presentingViewController:nil
                                          adSize:CGSizeZero
                                       adSection:0];
            }).to(raise_exception);

            objc_getAssociatedObject(view, STRGridlikeViewAdGeneratorKey) should be_nil;
        });

        it(@"does not assign an invalid data source or delegate", ^{
            STRGridlikeViewAdGenerator *oldGenerator = [[STRGridlikeViewAdGenerator alloc] initWithInjector:nil];
            UITableView *tableView = [UITableView new];
            id<UITableViewDataSource> fakeFataSource = nice_fake_for(@protocol(UITableViewDataSource));
            tableView.dataSource = fakeFataSource;

            objc_setAssociatedObject(view, STRGridlikeViewAdGeneratorKey, oldGenerator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            STRGridlikeViewDataSourceProxy *dataSourceProxy =
            [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"fakeAdCell"
                                                                     placementKey:@"fake-placement-key"
                                                         presentingViewController:nil
                                                                         injector:nil];
            expect(^{
                [generator placeAdInGridlikeView:tableView
                                 dataSourceProxy:dataSourceProxy
                           adCellReuseIdentifier:nil
                                    placementKey:nil
                        presentingViewController:nil
                                          adSize:CGSizeZero
                                       adSection:0];
            }).to_not(raise_exception);

            generator.originalDataSource should equal(fakeFataSource);
            dataSourceProxy should equal(([tableView dataSource]));
        });
    });
});

SPEC_END
