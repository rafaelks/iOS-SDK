#import "STRCollectionViewDataSourceProxy.h"
#import "STRInjector.h"
#import "STRAdGenerator.h"
#import "STRAppModule.h"
#import "STRFakeAdGenerator.h"
#import "STRFullCollectionViewDataSource.h"
#import "STRAdPlacementAdjuster.h"
#import "STRCollectionViewCell.h"
#import "STRCollectionViewAdGenerator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;


//Use default dequeue method (instead of str_dequeue) to avoid NSLog warnings
@interface STRCollectionViewDataSourceWithoutSpecialDequeue : STRCollectionViewDataSource
@end

@interface STRFullCollectionViewDataSourceWithoutSpecialDequeue : STRFullCollectionViewDataSource
@end

@implementation STRCollectionViewDataSourceWithoutSpecialDequeue
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"contentCell" forIndexPath:indexPath];

    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"item: %d, section: %d", indexPath.item, indexPath.section];
    [cell.contentView addSubview:label];

    return cell;
}
@end

@implementation STRFullCollectionViewDataSourceWithoutSpecialDequeue
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"contentCell" forIndexPath:indexPath];

    UILabel *label = [[UILabel alloc] init];
    label.text = [NSString stringWithFormat:@"item: %d, section: %d", indexPath.item, indexPath.section];
    [cell.contentView addSubview:label];

    return cell;
}
@end


SPEC_BEGIN(STRCollectionViewDataSourceProxySpec)

describe(@"STRCollectionViewDataSourceProxy", ^{
    __block STRCollectionViewDataSourceProxy *proxy;
    __block STRInjector *injector;
    __block STRAdGenerator *adGenerator;
    __block UIViewController *presentingViewController;
    __block UICollectionView *collectionView;
    __block STRCollectionViewDataSource *originalDataSource;

    STRCollectionViewDataSourceProxy *(^proxyWithDataSource)(id<UICollectionViewDataSource> dataSource) = ^STRCollectionViewDataSourceProxy *(id<UICollectionViewDataSource> dataSource) {
        STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

        return [[STRCollectionViewDataSourceProxy alloc] initWithOriginalDataSource:dataSource adjuster:adjuster adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController injector:injector];
    };

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        adGenerator = [STRFakeAdGenerator new];
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        presentingViewController = [UIViewController new];

        collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 500) collectionViewLayout:[UICollectionViewFlowLayout new]];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"contentCell"];

        originalDataSource = [STRCollectionViewDataSourceWithoutSpecialDequeue new];
        originalDataSource.itemsForEachSection = @[@2];

        proxy = proxyWithDataSource(originalDataSource);
        collectionView.dataSource = proxy;
    });

    describe(@"when the original data source implements all methods", ^{
        __block STRFullCollectionViewDataSourceWithoutSpecialDequeue *dataSource;

        beforeEach(^{
            dataSource = [STRFullCollectionViewDataSourceWithoutSpecialDequeue new];

            dataSource.numberOfSections = 2;
            dataSource.itemsForEachSection = @[@1, @1];

            [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCell"];

            proxy = proxyWithDataSource(dataSource);
            collectionView.dataSource = proxy;

            [collectionView layoutIfNeeded];
        });

        it(@"forwards numberOfSections to original data source", ^{
            [collectionView numberOfSections] should equal(2);
        });

        it(@"inserts a row into the first section", ^{
            [collectionView numberOfItemsInSection:0] should equal(2);
            [collectionView numberOfItemsInSection:1] should equal(1);
        });
    });

    describe(@"when the data source only implements required methods", ^{
        __block STRCollectionViewDataSourceWithoutSpecialDequeue *dataSource;

        beforeEach(^{
            dataSource = [STRCollectionViewDataSourceWithoutSpecialDequeue new];
            dataSource.itemsForEachSection = @[@2];

            [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCell"];

            proxy = proxyWithDataSource(dataSource);
            collectionView.dataSource = proxy;

            [collectionView layoutIfNeeded];
        });

        it(@"inserts an extra row in the first section", ^{
            [collectionView numberOfSections] should equal(1);
            [collectionView numberOfItemsInSection:0] should equal(3);
        });

        it(@"inserts an ad in the second row of the only section", ^{
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            [(UILabel *)cell.contentView.subviews[0] text] should equal(@"item: 0, section: 0");

            STRCollectionViewCell *adCell = (id)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
            adCell.adTitle.text should equal(@"Generic Ad Title");

            cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
            [(UILabel *)cell.contentView.subviews[0] text] should equal(@"item: 1, section: 0");
        });
    });

    describe(@"placing an ad in the collection view when the reuse identifier was badly registered", ^{
        it(@"throws Apple's exception if the sdk user does not register the identifier", ^{
            expect(^{
                [collectionView layoutIfNeeded];
            }).to(raise_exception());
        });

        it(@"throws an STR exception if the sdk user registers a cell that doesn't conform to STRAdView", ^{
            [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"adCell"];

            expect(^{
                [collectionView layoutIfNeeded];
            }).to(raise_exception());
        });
    });

    describe(@"-copyWithNewDataSource", ^{
        __block id<UICollectionViewDataSource> newDataSource;
        __block STRFullCollectionViewDataSourceWithoutSpecialDequeue *dataSource;

        beforeEach(^{
            dataSource = [STRFullCollectionViewDataSourceWithoutSpecialDequeue new];

            dataSource.numberOfSections = 2;
            dataSource.itemsForEachSection = @[@1, @1];
            proxy = proxyWithDataSource(dataSource);
        });

        it(@"returns a new delegateProxy with all the same values except the data source", ^{
            newDataSource = nice_fake_for(@protocol(UICollectionViewDataSource));
            STRCollectionViewDataSourceProxy *newProxy = [proxy copyWithNewDataSource:newDataSource];

            newProxy should_not be_same_instance_as(proxy);
            newProxy.originalDataSource should be_same_instance_as(newDataSource);
            newProxy.adjuster should equal(proxy.adjuster);
            newProxy.adCellReuseIdentifier should equal(@"adCell");
            newProxy.placementKey should equal(@"placementKey");
            newProxy.presentingViewController should be_same_instance_as(presentingViewController);
        });
    });
});

SPEC_END
