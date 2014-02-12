#import "UICollectionView+STR.h"
#import "STRCollectionViewDataSource.h"
#import "STRCollectionViewCell.h"
#import "STRAdPlacementAdjuster.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRCollectionViewAdGenerator.h"
#import "STRFullCollectionViewDataSource.h"
#import "STRFakeAdGenerator.h"

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
    __block STRCollectionViewAdGenerator *generator;

    beforeEach(^{
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 420) collectionViewLayout:[UICollectionViewFlowLayout new]];
        spy_on(collectionView);

        dataSource = [[STRFullCollectionViewDataSource alloc] init];
        dataSource.itemsForEachSection = @[@3, @3];
        dataSource.numberOfSections = 2;
        collectionView.dataSource = dataSource;

        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCellReuseIdentifier"];
        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"contentCell"];

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        spy_on(adPlacementAdjuster);

        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];
        spy_on([STRAdPlacementAdjuster class]);
        [STRAdPlacementAdjuster class] stub_method(@selector(adjusterWithInitialAdIndexPath:)).and_return(adPlacementAdjuster);

        [injector bind:[STRAdGenerator class] toInstance:[STRFakeAdGenerator new]];
        generator = [injector getInstance:[STRCollectionViewAdGenerator class]];
        [generator placeAdInCollectionView:collectionView
                     adCellReuseIdentifier:@"adCellReuseIdentifier"
                              placementKey:@"placementKey"
                  presentingViewController:nil
                         adInitialIndexPath:nil];


        [collectionView reloadData];
        [collectionView layoutIfNeeded];
    });

    describe(@"-str_dequeueReusableCellWithIdentifier:forIndexPath", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        });

        describe(@"when the collection view has been configured to display an ad", ^{
            context(@"when the index path is before the ad index path", ^{
                beforeEach(^{
                    [collectionView str_dequeueReusableCellWithReuseIdentifier:@"contentCell" forIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]] should_not be_nil;
                });

                it(@"calls through to original dequeue method without changing index path", ^{
                    collectionView should have_received(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:))
                    .with(@"contentCell", [NSIndexPath indexPathForItem:0 inSection:1]);
                });
            });

            context(@"when the index path is after the ad index path", ^{
                beforeEach(^{
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
                [collectionView str_numberOfItemsInSection:1] should equal(3);
            });
        });

        describe(@"when the section has 0 ads", ^{
            it(@"doesn't return an adjusted count", ^{
                [collectionView str_numberOfItemsInSection:0] should equal(3);
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
            [[collectionView str_visibleCellsWithoutAds] count] should equal(6);
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
                originalItemCount = collectionView.visibleCells.count;
                dataSource.itemsForEachSection = @[@3, @6]; //TODO: Why did 2/5 cause cedar to fail?
                [collectionView str_insertItemsAtIndexPaths:externalIndexPaths];
            });

            it(@"tells the collection view to insert the items at the correct index paths", ^{
                collectionView should have_received(@selector(insertItemsAtIndexPaths:)).with(trueIndexPaths);

                collectionView.visibleCells.count should equal(originalItemCount + 3);
            });
            
            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willInsertRowsAtExternalIndexPaths:)).with(externalIndexPaths);
                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForItem:3 inSection:1]);
            });
        });
    });

    describe(@"-str_deleteItemsAtIndexPaths:", ^{
        __block NSArray *externalIndexPaths;
        __block NSArray *trueIndexPaths;

        beforeEach(^{
            externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1],
                                   [NSIndexPath indexPathForRow:1 inSection:1]];
            trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1],
                               [NSIndexPath indexPathForRow:2 inSection:1]];
        });

        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:0]]];
        });

        describe(@"deleting items in a collectionView with an ad", ^{
            __block NSInteger originalRowCount;

            beforeEach(^{
                originalRowCount = collectionView.visibleCells.count;
                dataSource.itemsForEachSection = @[@3, @1];
                [collectionView str_deleteItemsAtIndexPaths:externalIndexPaths];
            });

            it(@"tells the collection to delete the correct items", ^{
                collectionView should have_received(@selector(deleteItemsAtIndexPaths:)).with(trueIndexPaths);
                collectionView.visibleCells.count should equal(originalRowCount - 2);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willDeleteRowsAtExternalIndexPaths:)).with(externalIndexPaths);

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForItem:0 inSection:1]);
            });
        });
    });

    describe(@"-str_moveItemAtIndexPath:toIndexPath:", ^{
        __block NSIndexPath *externalStartIndexPath;
        __block NSIndexPath *externalEndIndexPath;

        beforeEach(^{
            externalStartIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
            externalEndIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
        });

        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_moveItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1] toIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
        });

        describe(@"moving items in a collectionview with an ad", ^{
            __block NSInteger originalRowCount;

            beforeEach(^{
                originalRowCount = collectionView.visibleCells.count;
                [collectionView str_moveItemAtIndexPath:externalStartIndexPath
                                            toIndexPath:externalEndIndexPath];
            });

            it(@"tells the collection view to move the correct items", ^{
                collectionView should have_received(@selector(moveItemAtIndexPath:toIndexPath:))
                .with([NSIndexPath indexPathForItem:2 inSection:1], [NSIndexPath indexPathForItem:0 inSection:1]);

                collectionView.visibleCells.count should equal(originalRowCount);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willMoveRowAtExternalIndexPath:toExternalIndexPath:)).with(externalStartIndexPath, externalEndIndexPath);

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
        });
    });

    describe(@"-str_cellForItemAtIndexPath:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:1]];
        });

        it(@"returns the cell at the adjusted index path", ^{
            UICollectionViewCell *cell = [collectionView str_cellForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];

            cell should be_same_instance_as([collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:1]]);
        });
    });

    describe(@"-str_indexPathsForVisibleItems", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_indexPathsForVisibleItems];
        });

        it(@"returns an array of NSIndexPaths without the ad cell", ^{
            [collectionView.visibleCells count] should equal(7);

            NSArray *returnedIndexPaths = [collectionView str_indexPathsForVisibleItems];
            [returnedIndexPaths count] should equal(6);
            returnedIndexPaths should contain([NSIndexPath indexPathForItem:0 inSection:0]);
            returnedIndexPaths should contain([NSIndexPath indexPathForItem:1 inSection:0]);
            returnedIndexPaths should contain([NSIndexPath indexPathForItem:2 inSection:0]);
            returnedIndexPaths should contain([NSIndexPath indexPathForItem:0 inSection:1]);
            returnedIndexPaths should contain([NSIndexPath indexPathForItem:1 inSection:1]);
            returnedIndexPaths should contain([NSIndexPath indexPathForItem:2 inSection:1]);
        });
    });

    describe(@"-str_indexPathForCell:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_indexPathForCell:nil];
        });

        it(@"returns an adjusted index path if not an ad cell", ^{
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:1]];
            NSIndexPath *returnedIndexPath = [collectionView str_indexPathForCell:cell];

            collectionView should have_received(@selector(indexPathForCell:)).with(cell);
            returnedIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:1]);
        });

        it(@"returns nil if the cell passed in is an ad cell", ^{
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]];
            NSIndexPath *returnedIndexPath = [collectionView str_indexPathForCell:cell];

            collectionView should have_received(@selector(indexPathForCell:)).with(cell);
            returnedIndexPath should be_nil;
        });

        it(@"returns nil if the cell passed in is nil", ^{
            NSIndexPath *returnedIndexPath = [collectionView str_indexPathForCell:nil];

            collectionView should have_received(@selector(indexPathForCell:)).with(nil);
            returnedIndexPath should be_nil;
        });
    });

    describe(@"–str_indexPathForItemAtPoint:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_indexPathForItemAtPoint:CGPointZero];
        });

        it(@"returns an adjusted index path if not a point within ad cell", ^{
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:3 inSection:1]];

            NSIndexPath *returnedIndexPath = [collectionView str_indexPathForItemAtPoint:cell.center];

            collectionView should have_received(@selector(indexPathForItemAtPoint:)).with(cell.center);
            returnedIndexPath should equal([NSIndexPath indexPathForItem:2 inSection:1]);
        });

        it(@"returns nil if the point passed in is within an ad cell", ^{
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:1]];
            NSIndexPath *returnedIndexPath = [collectionView str_indexPathForItemAtPoint:cell.center];

            collectionView should have_received(@selector(indexPathForItemAtPoint:)).with(cell.center);
            returnedIndexPath should be_nil;
        });

        it(@"returns nil if the point passed in is out of bounds", ^{
            NSIndexPath *returnedIndexPath = [collectionView str_indexPathForItemAtPoint:CGPointMake(-1, -1)];

            collectionView should have_received(@selector(indexPathForItemAtPoint:)).with(CGPointMake(-1, -1));
            returnedIndexPath should be_nil;
        });
    });

    describe(@"-str_reloadDataWithAdIndexPath:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView){
            [noAdCollectionView str_reloadDataWithAdIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        });

        it(@"reloads the collectionview, inserting a row at the new index path", ^{
            [(id<CedarDouble>)collectionView reset_sent_messages];
            [collectionView str_reloadDataWithAdIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];

            collectionView should have_received(@selector(reloadData));
            [collectionView layoutIfNeeded]; // ?

            [collectionView numberOfItemsInSection:0] should equal(4);
            [collectionView numberOfItemsInSection:1] should equal(3);

            STRCollectionViewCell *adCell = (STRCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
            adCell.adTitle.text should equal(@"Generic Ad Title");
        });

        it(@"places the ad at the initialIndexPath", ^{
            [(id<CedarDouble>)collectionView reset_sent_messages];
            [collectionView str_reloadDataWithAdIndexPath:nil];
            collectionView should have_received(@selector(reloadData));
            [collectionView layoutIfNeeded];

            STRCollectionViewCell *adCell = (STRCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            adCell.adTitle.text should equal(@"Generic Ad Title");
        });

        it(@"always ensures that index path is valid", ^{
            spy_on(generator);
            [collectionView str_reloadDataWithAdIndexPath:nil];
            generator should have_received(@selector(initialIndexPathForAd:preferredStartingIndexPath:)).with(collectionView, nil);
        });
    });

    describe(@"-str_reloadSections", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView) {
            [noAdCollectionView str_reloadSections:nil];
        });

        context(@"when the new section size is larger than ad position", ^{
            it(@"the ad remains in the same indexpath", ^{
                [collectionView str_reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];

                collectionView should have_received(@selector(reloadSections:))
                .with([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);

                STRCollectionViewCell *adCell = (STRCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                adCell.adTitle.text should equal(@"Generic Ad Title");
            });
        });

        context(@"when the new section size is smaller than ad position", ^{
            it(@"adjusts the ad to be bottom-most in the section", ^{
                dataSource.itemsForEachSection = @[@0, @0];

                [collectionView str_reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];

                collectionView should have_received(@selector(reloadSections:))
                .with([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]);
                STRCollectionViewCell *adCell = (STRCollectionViewCell *)[collectionView.visibleCells lastObject];
                adCell.adTitle.text should equal(@"Generic Ad Title");
            });
        });
    });

    describe(@"-str_reloadItemsAtIndexPaths:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView) {
            [noAdCollectionView str_reloadItemsAtIndexPaths:nil];
        });

        it(@"reloads those adjusted rows", ^{
            [collectionView str_reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                          [NSIndexPath indexPathForRow:1 inSection:1],
                                                          [NSIndexPath indexPathForRow:2 inSection:1]]];

            collectionView should have_received(@selector(reloadItemsAtIndexPaths:))
            .with(@[[NSIndexPath indexPathForRow:0 inSection:1],
                    [NSIndexPath indexPathForRow:2 inSection:1],
                    [NSIndexPath indexPathForRow:3 inSection:1]]);
        });
    });

    describe(@"–str_scrollToItemAtIndexPath:atScrollPosition:animated:", ^{
        itThrowsIfCollectionWasntConfigured(^(UICollectionView *noAdCollectionView) {
            [noAdCollectionView str_scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        });

        it(@"scrolls to the adjusted index path", ^{
            collectionView.frame = [[collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] frame];

            [collectionView str_scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];

            NSIndexPath *trueIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
            collectionView should have_received(@selector(scrollToItemAtIndexPath:atScrollPosition:animated:)).with(trueIndexPath, UICollectionViewScrollPositionTop, NO);
            collectionView.contentOffset should equal([collectionView layoutAttributesForItemAtIndexPath:trueIndexPath].frame.origin);
        });

        it(@"is able to scroll to NSNotFound", ^{
            collectionView.frame = [[collectionView layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] frame];

            [collectionView str_scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];

            collectionView.contentOffset should equal(CGPointZero);
        });
    });
});

SPEC_END
