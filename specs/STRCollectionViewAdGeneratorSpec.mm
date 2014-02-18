#import "SharethroughSDK.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRCollectionViewDataSource.h"
#import "STRCollectionViewCell.h"
#import "STRCollectionViewDelegate.h"
#import "STRIndexPathDelegateProxy.h"
#import "STRFullCollectionViewDataSource.h"
#import "STRFakeAdGenerator.h"
#import "STRGridlikeViewDataSourceProxy.h"
#import "STRGridlikeViewAdGenerator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const STRGridlikeViewAdGeneratorKey;

SPEC_BEGIN(STRCollectionViewAdGeneratorSpec)

describe(@"STRGridlikeViewAdGenerator UICollectionView", ^{
    __block STRGridlikeViewAdGenerator *collectionViewAdGenerator;
    __block STRAdGenerator *adGenerator;
    __block UICollectionView *collectionView;
    __block UIViewController *presentingViewController;

    __block STRCollectionViewDataSource *dataSource;

    beforeEach(^{
        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        adGenerator = [STRFakeAdGenerator new];
        spy_on(adGenerator);
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        collectionViewAdGenerator = [injector getInstance:[STRGridlikeViewAdGenerator class]];

        presentingViewController = [UIViewController new];
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 400)
                                            collectionViewLayout:[UICollectionViewFlowLayout new]];
        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCell"];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"contentCell"];

    });

    describe(@"placing an ad in the collection view", ^{
        beforeEach(^{
            dataSource = [STRCollectionViewDataSource new];
            dataSource.itemsForEachSection = @[@2];
            collectionView.dataSource = dataSource;

            [collectionViewAdGenerator placeAdInGridlikeView:collectionView
                                       adCellReuseIdentifier:@"adCell"
                                                placementKey:@"placementKey"
                                    presentingViewController:presentingViewController
                                                      adSize:CGSizeZero
                                          adInitialIndexPath:nil];
            [collectionView layoutIfNeeded];
        });

        it(@"stores itself as an associated object of the collection view", ^{
            objc_getAssociatedObject(collectionView, STRGridlikeViewAdGeneratorKey) should be_same_instance_as(collectionViewAdGenerator);
        });
    });

    describe(@"taking over the collectionview delegate", ^{
        __block STRCollectionViewDelegate *collectionViewController;

        beforeEach(^{
            collectionViewController = [STRCollectionViewDelegate new];

            collectionView.delegate = collectionViewController;
            [collectionView registerClass:[STRCollectionViewCell class]
               forCellWithReuseIdentifier:@"adCell"];

            [collectionViewAdGenerator placeAdInGridlikeView:collectionView
                                       adCellReuseIdentifier:@"adCell"
                                                placementKey:@"placementKey"
                                    presentingViewController:presentingViewController
                                                      adSize:CGSizeZero
                                          adInitialIndexPath:nil];
            [collectionView layoutIfNeeded];
        });

        it(@"collectionview's delegate points to a delegateProxy", ^{
            id<UICollectionViewDelegate> delegate = collectionView.delegate;

            [delegate isKindOfClass:[STRIndexPathDelegateProxy class]] should be_truthy;
        });

        it(@"delegateProxy points to collectionview's original delegate", ^{
            STRIndexPathDelegateProxy *proxy = (id)collectionView.delegate;
            proxy.originalDelegate should be_same_instance_as(collectionViewController);
        });

        it(@"provides an accessor to the original delgate", ^{
            collectionViewAdGenerator.originalDelegate should be_same_instance_as(collectionViewController);
        });

        it(@"provides a setter to modify the original delegate", ^{
            STRCollectionViewDelegate *newDelegate = [STRCollectionViewDelegate new];
            STRIndexPathDelegateProxy *oldProxy = (id)collectionView.delegate;

            [collectionViewAdGenerator setOriginalDelegate:newDelegate gridlikeView:collectionView];

            collectionViewAdGenerator.originalDelegate should be_same_instance_as(newDelegate);
            collectionView.delegate should_not be_same_instance_as(oldProxy);
            collectionView.delegate should be_instance_of([STRIndexPathDelegateProxy class]);
        });
    });

    describe(@"taking over the collection view data source", ^{
        __block STRCollectionViewDataSource *dataSource;

        beforeEach(^{
            dataSource = [STRCollectionViewDataSource new];
            collectionView.dataSource = dataSource;

            [collectionViewAdGenerator placeAdInGridlikeView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adSize:CGSizeZero adInitialIndexPath:nil ];
            [collectionView layoutIfNeeded];
        });

        it(@"points the collection view's data source to a delegateProxy", ^{
            id<UICollectionViewDataSource>dataSource = collectionView.dataSource;
            dataSource should be_instance_of([STRGridlikeViewDataSourceProxy class]);
        });

        it(@"points the delegateProxy's data source to the table view's original data source", ^{
            STRGridlikeViewDataSourceProxy *proxy = (STRGridlikeViewDataSourceProxy *)collectionView.dataSource;
            proxy.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"provides an accessor to the original data source", ^{
            collectionViewAdGenerator.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"provides a setter to modify the original data source", ^{
            STRCollectionViewDataSource *newDataSource = [STRCollectionViewDataSource new];
            STRGridlikeViewDataSourceProxy *proxy = (STRGridlikeViewDataSourceProxy *)collectionView.dataSource;
            [collectionViewAdGenerator setOriginalDataSource:newDataSource gridlikeView:collectionView];

            collectionViewAdGenerator.originalDataSource should be_same_instance_as(newDataSource);
            collectionView.dataSource should_not be_same_instance_as(proxy);
            collectionView.dataSource should be_instance_of([STRGridlikeViewDataSourceProxy class]);
        });
    });

    describe(@"placing ad with a custom index path", ^{
        __block STRFullCollectionViewDataSource *dataSource;

        beforeEach(^{
            dataSource = [STRFullCollectionViewDataSource new];
            collectionView.dataSource = dataSource;
            dataSource.itemsForEachSection = @[@0, @2];
        });

        it(@"puts the ad there", ^{
            [collectionViewAdGenerator placeAdInGridlikeView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adSize:CGSizeZero adInitialIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            [collectionView layoutIfNeeded];
            [collectionView numberOfItemsInSection:1] should equal(3);

            [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] should be_instance_of([STRCollectionViewCell class]);
        });

        context(@"and the index path is out of bounds", ^{
            it(@"raises an exception", ^{
                expect(^{
                    [collectionViewAdGenerator placeAdInGridlikeView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adSize:CGSizeZero adInitialIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
                }).to(raise_exception());
            });
        });

        context(@"and then index path would be valid when the ad is inserted", ^{
            it(@"is still able to place the ad there", ^{
                [collectionViewAdGenerator placeAdInGridlikeView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adSize:CGSizeZero adInitialIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                [collectionView layoutIfNeeded];
                [collectionView numberOfItemsInSection:1] should equal(3);
                [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should be_instance_of([STRCollectionViewCell class]);
            });
        });
    });

});

SPEC_END
