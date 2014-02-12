#import "STRCollectionViewAdGenerator.h"
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
#import "STRCollectionViewDataSourceProxy.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRCollectionViewAdGeneratorSpec)

describe(@"STRCollectionViewAdGenerator", ^{
    __block STRCollectionViewAdGenerator *collectionViewAdGenerator;
    __block STRAdGenerator *adGenerator;
    __block UICollectionView *collectionView;
    __block UIViewController *presentingViewController;

    __block STRCollectionViewDataSource *dataSource;

    beforeEach(^{
        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        adGenerator = [STRFakeAdGenerator new];
        spy_on(adGenerator);
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        collectionViewAdGenerator = [injector getInstance:[STRCollectionViewAdGenerator class]];

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

            [collectionViewAdGenerator placeAdInCollectionView:collectionView
                                         adCellReuseIdentifier:@"adCell"
                                                  placementKey:@"placementKey"
                                      presentingViewController:presentingViewController
                                            adInitialIndexPath:nil];
            [collectionView layoutIfNeeded];
        });
        it(@"stores itself as an associated object of the collection view", ^{
            objc_getAssociatedObject(collectionView, STRCollectionViewAdGeneratorKey) should be_same_instance_as(collectionViewAdGenerator);
        });

        describe(@"when the data source only implements required methods", ^{
            it(@"inserts an extra row in the first section", ^{
                [collectionView numberOfSections] should equal(1);
                [collectionView numberOfItemsInSection:0] should equal(3);
            });

            it(@"inserts an ad into the second row of the first section", ^{
                UICollectionViewCell *contentCell = collectionView.visibleCells[0];
                [(UILabel *)[contentCell.contentView.subviews lastObject] text] should equal(@"item: 0, section: 0");

                STRCollectionViewCell *adCell = (STRCollectionViewCell *) collectionView.visibleCells[1];
                adCell should be_instance_of([STRCollectionViewCell class]);

                adGenerator should have_received(@selector(placeAdInView:placementKey:presentingViewController:delegate:)).with(adCell, @"placementKey", presentingViewController, nil);

                contentCell = collectionView.visibleCells[2];
                [(UILabel *)[contentCell.contentView.subviews lastObject] text] should equal(@"item: 1, section: 0");
            });
        });

        describe(@"when the data source implements all methods", ^{
            __block STRFullCollectionViewDataSource<UICollectionViewDataSource> *dataSource;

            beforeEach(^{
                dataSource = [STRFullCollectionViewDataSource new];
                spy_on(dataSource);
                collectionView.dataSource = dataSource;
            });

            it(@"forwards selectors to the data source", ^{
                [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adInitialIndexPath:nil];
                [collectionView layoutIfNeeded];

                [collectionView numberOfSections];
                dataSource should have_received(@selector(numberOfSectionsInCollectionView:));
            });

            describe(@"and the original data source reports there is more than one section", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 2;
                    dataSource.itemsForEachSection = @[@1, @1];

                    [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adInitialIndexPath:nil];
                    [collectionView layoutIfNeeded];
                });

                it(@"only inserts a row in the first section", ^{
                    [collectionView numberOfItemsInSection:0] should equal(2);
                    [collectionView numberOfItemsInSection:1] should equal(1);
                });
            });
        });
    });

    describe(@"taking over the collectionview delegate", ^{
        __block STRCollectionViewDelegate *collectionViewController;

        beforeEach(^{
            collectionViewController = [STRCollectionViewDelegate new];

            collectionView.delegate = collectionViewController;
            [collectionView registerClass:[STRCollectionViewCell class]
               forCellWithReuseIdentifier:@"adCell"];

            [collectionViewAdGenerator placeAdInCollectionView:collectionView
                                         adCellReuseIdentifier:@"adCell"
                                                  placementKey:@"placementKey"
                                      presentingViewController:presentingViewController
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

            [collectionViewAdGenerator setOriginalDelegate:newDelegate collectionView:collectionView];

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

            [collectionViewAdGenerator placeAdInCollectionView:collectionView
                                         adCellReuseIdentifier:@"adCell"
                                                  placementKey:@"placementKey"
                                      presentingViewController:presentingViewController
                                            adInitialIndexPath:nil];
            [collectionView layoutIfNeeded];
        });

        it(@"points the collection view's data source to a delegateProxy", ^{
            id<UICollectionViewDataSource>dataSource = collectionView.dataSource;
            dataSource should be_instance_of([STRCollectionViewDataSourceProxy class]);
        });

        it(@"points the delegateProxy's data source to the table view's original data source", ^{
            STRCollectionViewDataSourceProxy *proxy = collectionView.dataSource;
            proxy.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"provides an accessor to the original data source", ^{
            collectionViewAdGenerator.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"provides a setter to modify the original data source", ^{
            STRCollectionViewDataSource *newDataSource = [STRCollectionViewDataSource new];
            STRCollectionViewDataSourceProxy *proxy = (STRCollectionViewDataSourceProxy *)collectionView.dataSource;
            [collectionViewAdGenerator setOriginalDataSource:newDataSource collectionView:collectionView];

            collectionViewAdGenerator.originalDataSource should be_same_instance_as(newDataSource);
            collectionView.dataSource should_not be_same_instance_as(proxy);
            collectionView.dataSource should be_instance_of([STRCollectionViewDataSourceProxy class]);
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
            [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adInitialIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            [collectionView layoutIfNeeded];
            [collectionView numberOfItemsInSection:1] should equal(3);

            [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] should be_instance_of([STRCollectionViewCell class]);
        });

        context(@"and the index path is out of bounds", ^{
            it(@"raises an exception", ^{
                expect(^{
                    [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adInitialIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
                }).to(raise_exception());
            });
        });

        context(@"and then index path would be valid when the ad is inserted", ^{
            it(@"is still able to place the ad there", ^{
                [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adInitialIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                [collectionView layoutIfNeeded];
                [collectionView numberOfItemsInSection:1] should equal(3);
                [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should be_instance_of([STRCollectionViewCell class]);
            });
        });
    });

});

SPEC_END
