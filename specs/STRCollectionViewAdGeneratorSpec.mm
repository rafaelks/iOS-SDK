#import "STRCollectionViewAdGenerator.h"
#import "SharethroughSDK.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRCollectionViewDataSource.h"
#import "STRCollectionViewCell.h"
#import "STRCollectionViewDelegate.h"
#import "STRCollectionViewDelegateProxy.h"

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

        adGenerator = nice_fake_for([STRAdGenerator class]);
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        collectionViewAdGenerator = [injector getInstance:[STRCollectionViewAdGenerator class]];

        presentingViewController = [UIViewController new];
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 400)
                                            collectionViewLayout:[UICollectionViewFlowLayout new]];
        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCell"];
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"contentCell"];

        dataSource = [STRCollectionViewDataSource new];
        dataSource.itemsForEachSection = @[@2];
        collectionView.dataSource = dataSource;
    });

    describe(@"placing an ad in the collection view", ^{
        it(@"stores itself as an associated object of the collection view", ^{
            [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
            [collectionView layoutIfNeeded];

            objc_getAssociatedObject(collectionView, STRCollectionViewAdGeneratorKey) should be_same_instance_as(collectionViewAdGenerator);
        });

        describe(@"when the data source only implements required methods", ^{
            beforeEach(^{
                [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
                [collectionView layoutIfNeeded];
            });

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
//
//        describe(@"when the data source implements all methods", ^{
//            __block STRFullCollectionViewDataSource<UICollectionViewDataSource> *dataSource;
//
//            beforeEach(^{
//                dataSource = [STRFullCollectionViewDataSource new];
//                collectionView.dataSource = dataSource;
//            });
//
//            describe(@"and the original data source reports there is more than one section", ^{
//                beforeEach(^{
//                    dataSource.numberOfSections = 2;
//                    dataSource.rowsForEachSection = @[@1, @1];
//
//                    [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10];
//                    [collectionView layoutIfNeeded];
//                });
//
//                it(@"only inserts a row in the first section", ^{
//                    [collectionView numberOfRowsInSection:0] should equal(2);
//                    [collectionView numberOfRowsInSection:1] should equal(1);
//                });
//            });
//
//            it(@"forwards other selectors to the data source", ^{
//                [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10];
//                [collectionView layoutIfNeeded];
//
//                [collectionView footerViewForSection:0].textLabel.text should equal(@"title for footer");
//            });
//        });
    });
//
//    describe(@"placing an ad in the collection view when the reuse identifier was badly registered", ^{
//        __block STRCollectionViewDataSource *dataSource;
//
//        beforeEach(^{
//            dataSource = [STRCollectionViewDataSource new];
//            collectionView.dataSource = dataSource;
//
//            [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10];
//        });
//
//        it(@"throws an exception if the sdk user does not register the identifier", ^{
//            expect(^{
//                [collectionView layoutIfNeeded];
//            }).to(raise_exception());
//        });
//
//        it(@"throws an exception if the sdk user registers a cell that doesn't conform to STRAdView", ^{
//            [collectionView registerClass:[UICollectionViewCell class] forCellReuseIdentifier:@"adCell"];
//
//            expect(^{
//                [collectionView layoutIfNeeded];
//            }).to(raise_exception());
//        });
//    });
    describe(@"wiring up collectionview delegate", ^{
        __block STRCollectionViewDelegate *collectionViewController;

        beforeEach(^{
            collectionViewController = [STRCollectionViewDelegate new];

            collectionView.delegate = collectionViewController;
            [collectionView registerClass:[STRCollectionViewCell class]     forCellWithReuseIdentifier:@"adCell"];

            [collectionViewAdGenerator placeAdInCollectionView:collectionView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
            [collectionView layoutIfNeeded];
        });

        it(@"collectionview's delegate points to a proxy", ^{
            id<UICollectionViewDelegate> delegate = collectionView.delegate;

            [delegate isKindOfClass:[STRCollectionViewDelegateProxy class]] should be_truthy;
        });

        it(@"proxy points to collectionview's original delegate", ^{
            STRCollectionViewDelegateProxy *proxy = collectionView.delegate;
            proxy.originalDelegate should be_same_instance_as(collectionViewController);
        });
    });

});

SPEC_END
