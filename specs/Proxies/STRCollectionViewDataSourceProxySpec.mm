#import "STRGridlikeViewDataSourceProxy.h"
#import "STRInjector.h"
#import "STRAdGenerator.h"
#import "STRAppModule.h"
#import "STRFakeAdGenerator.h"
#import "STRFullCollectionViewDataSource.h"
#import "STRAdPlacementAdjuster.h"
#import "STRCollectionViewCell.h"

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
    label.text = [NSString stringWithFormat:@"item: %ld, section: %d", (long)indexPath.item, indexPath.section];
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

describe(@"STRGridlikeViewDataSourceProxy UICollectionViewDataSource", ^{
    __block STRGridlikeViewDataSourceProxy *proxy;
    __block STRInjector *injector;
    __block STRAdGenerator *adGenerator;
    __block UIViewController *presentingViewController;
    __block UICollectionView *collectionView;
    __block STRCollectionViewDataSource *originalDataSource;
    
    STRGridlikeViewDataSourceProxy *(^proxyWithDataSource)(id<UICollectionViewDataSource> dataSource) = ^STRGridlikeViewDataSourceProxy *(id<UICollectionViewDataSource> dataSource) {
        STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

        STRGridlikeViewDataSourceProxy *dataSourceProxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController injector:injector];
        dataSourceProxy.originalDataSource = dataSource;
        dataSourceProxy.adjuster = adjuster;
        
        return dataSourceProxy;
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
        
        describe(@"when an ad is loaded", ^{
            beforeEach(^{
                [proxy prefetchAdForGridLikeView:collectionView];
            });
            
            it(@"inserts a row into the first section", ^{
                [collectionView numberOfItemsInSection:0] should equal(2);
                [collectionView numberOfItemsInSection:1] should equal(1);
            });
        });
        
        describe(@"when an ad is not loaded", ^{
            it(@"doesn't insert any rows in any sections", ^{
                [collectionView numberOfItemsInSection:0] should equal(1);
                [collectionView numberOfItemsInSection:1] should equal(1);
            });
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
            
            [proxy prefetchAdForGridLikeView:collectionView];
            
            [collectionView layoutIfNeeded];
        });
        
        describe(@"when an ad is loaded", ^{
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
    });
    
    describe(@"placing an ad in the collection view when the reuse identifier was badly registered", ^{
        it(@"throws Apple's exception if the sdk user does not register the identifier", ^{
            expect(^{
                [proxy prefetchAdForGridLikeView:collectionView];
                [collectionView layoutIfNeeded];
            }).to(raise_exception());
        });
        
        it(@"throws an STR exception if the sdk user registers a cell that doesn't conform to STRAdView", ^{
            [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"adCell"];
            
            expect(^{
                [proxy prefetchAdForGridLikeView:collectionView];
                [collectionView layoutIfNeeded];
            }).to(raise_exception());
        });
    });
});

SPEC_END
