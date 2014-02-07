#import "UICollectionView+STR.h"
#import "STRCollectionViewDataSource.h"
#import "STRCollectionViewCell.h"
#import "STRAdPlacementAdjuster.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRCollectionViewAdGenerator.h"
#import "STRFullCollectionViewDataSource.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(UICollectionViewSpec)

typedef void(^TriggerBlock)(UICollectionView *noAdCollectionView);
void(^itThrowsIfCollectionWasntConfigured)(TriggerBlock) = ^(TriggerBlock trigger){
    describe(@"when the collection view wasn't configured", ^{
        __block NSInteger originalRowCount;
        __block UICollectionView *noAdCollectionView;
        __block STRCollectionViewDataSource *dataSource;

        beforeEach(^{
            noAdCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 1000, 1000) collectionViewLayout:[UICollectionViewFlowLayout new]];
            dataSource = [[STRCollectionViewDataSource alloc] init];
            noAdCollectionView.dataSource = dataSource;

            [noAdCollectionView reloadData];

            originalRowCount = noAdCollectionView.visibleCells.count;
        });

        it(@"raises an exception", ^{
            expect(^{trigger(noAdCollectionView);}).to(raise_exception);

            noAdCollectionView.visibleCells.count should equal(originalRowCount);
        });
    });
};


describe(@"UICollectionView+STR", ^{
    __block UICollectionView *collectionView;
    __block STRFullCollectionViewDataSource *dataSource;
    __block STRAdPlacementAdjuster *adPlacementAdjuster;
    __block STRCollectionViewCell *adCell;

    beforeEach(^{
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 420) collectionViewLayout:[UICollectionViewFlowLayout new]];

        dataSource = [[STRFullCollectionViewDataSource alloc] init];
        dataSource.itemsForEachSection = @[@2, @2];
        dataSource.numberOfSections = 2;
        collectionView.dataSource = dataSource;

        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCellReuseIdentifier"];
        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"contentCell"];

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        spy_on(adPlacementAdjuster);

        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        [injector bind:[STRAdGenerator class] toInstance:nice_fake_for([STRAdGenerator class])];

        spy_on([STRAdPlacementAdjuster class]);
        [STRAdPlacementAdjuster class] stub_method(@selector(adjusterWithInitialAdIndexPath:)).and_return(adPlacementAdjuster);

        STRCollectionViewAdGenerator *generator = [injector getInstance:[STRCollectionViewAdGenerator class]];
        [generator placeAdInCollectionView:collectionView
                     adCellReuseIdentifier:@"adCellReuseIdentifier"
                              placementKey:@"placementKey"
                  presentingViewController:nil];

        [collectionView reloadData];
        [collectionView layoutIfNeeded];
        adCell = (STRCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]];
    });

    describe(@"-str_dequeueReusableCellWithIdentifier:forIndexPath", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        });

        describe(@"when the collection view has been configured to display an ad", ^{
            context(@"when the index path is before the ad index path", ^{
                beforeEach(^{
                    spy_on(collectionView);

                    [collectionView str_dequeueReusableCellWithReuseIdentifier:@"contentCell" forIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]] should_not be_nil;
                });

                it(@"calls through to original dequeue method without changing index path", ^{
                    collectionView should have_received(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:))
                    .with(@"contentCell", [NSIndexPath indexPathForItem:0 inSection:1]);
                });
            });

            context(@"when the index path is after the ad index path", ^{
                beforeEach(^{
                    spy_on(collectionView);

                    [collectionView str_dequeueReusableCellWithReuseIdentifier:@"contentCell" forIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]] should_not be_nil;
                });

                it(@"calls through to original dequeue method after changing index path", ^{
                    collectionView should have_received(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:))
                    .with(@"contentCell", [NSIndexPath indexPathForItem:2 inSection:1]);
                });
            });

        });
    });

    describe(@"-str_numberOfItemsInSection:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_numberOfItemsInSection:0];
        });

        describe(@"when the section contains an ad", ^{
            it(@"does not include that ad in the count", ^{
                [collectionView str_numberOfItemsInSection:1] should equal(2);
            });
        });

        describe(@"when the section has 0 ads", ^{
            it(@"doesn't return an adjusted count", ^{
                [collectionView str_numberOfItemsInSection:0] should equal(2);
            });
        });
    });

    describe(@"-str_visibleCellsWithoutAds:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_visibleCellsWithoutAds];
        });

        it(@"does not include the ad", ^{
            [collectionView str_visibleCellsWithoutAds] should_not contain(adCell);
        });

        it(@"does include all visible content cells", ^{
            [[collectionView str_visibleCellsWithoutAds] count] should equal(4);
        });
    });

    describe(@"-str_insertItemsAtIndexPaths:", ^{
        __block NSArray *externalIndexPaths;
        __block NSArray *trueIndexPaths;

        beforeEach(^{
            externalIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:1],
                                   [NSIndexPath indexPathForRow:0 inSection:1],
                                   [NSIndexPath indexPathForRow:4 inSection:1]];
            trueIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:1],
                               [NSIndexPath indexPathForRow:0 inSection:1],
                               [NSIndexPath indexPathForRow:5 inSection:1]];
        });

        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
        });

        describe(@"inserting items in a collectionView with an ad", ^{
            __block NSInteger originalItemCount;

            beforeEach(^{
                spy_on(collectionView);
                originalItemCount = collectionView.visibleCells.count;
                dataSource.itemsForEachSection = @[@2, @5];
                [collectionView str_insertItemsAtIndexPaths:externalIndexPaths];
            });

            it(@"tells the table view to insert the rows at the correct index paths", ^{
                collectionView should have_received(@selector(insertItemsAtIndexPaths:)).with(trueIndexPaths);

                collectionView.visibleCells.count should equal(originalItemCount + 3);
            });
            
            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willInsertRowsAtExternalIndexPaths:)).with(externalIndexPaths);
                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForItem:3 inSection:1]);
            });
        });
    });
});

SPEC_END
