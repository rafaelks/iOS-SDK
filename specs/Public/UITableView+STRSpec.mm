#import "UITableView+STR.h"
#import "STRAdPlacementAdjuster.h"
#import "STRTableViewDataSource.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewDelegate.h"
#import "STRGridlikeViewAdGenerator.h"
#import <objc/runtime.h>
#import "STRAdGenerator.h"
#import "STRAppModule.h"
#import "STRTableViewCell.h"
#import "STRFakeAdGenerator.h"
#import "STRGridlikeViewDataSourceProxy.h"
#import "STRAdCache.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const STRGridlikeViewAdGeneratorKey;

SPEC_BEGIN(UITableViewSpec)

typedef void(^TriggerBlock)(UITableView *noAdTableView);
void(^itThrowsIfTableWasntConfigured)(TriggerBlock) = ^(TriggerBlock trigger){
    describe(@"when the table view wasn't configured", ^{
        __block NSInteger originalRowCount;
        __block UITableView *noAdTableView;
        __block STRTableViewDataSource *dataSource;

        beforeEach(^{
            noAdTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
            dataSource = [[STRTableViewDataSource alloc] init];
            noAdTableView.dataSource = dataSource;
            
            [noAdTableView reloadData];
            
            originalRowCount = noAdTableView.visibleCells.count;
        });
        
        it(@"raises an exception", ^{
            expect(^{trigger(noAdTableView);}).to(raise_exception);
            
            noAdTableView.visibleCells.count should equal(originalRowCount);
        });
    });
};

describe(@"UITableView+STR", ^{
    __block UITableView *tableView;
    __block STRTableViewDelegate *delegate;
    __block STRFullTableViewDataSource *dataSource;
    __block STRAdPlacementAdjuster *adPlacementAdjuster;
    __block STRGridlikeViewAdGenerator *tableViewAdGenerator;
    __block STRGridlikeViewDataSourceProxy *dataSourceProxy;
    __block NSString *fakePlacementKey;
    __block STRAdCache *fakeAdCache;

    beforeEach(^{
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
        spy_on(tableView);
        
        delegate = [[STRTableViewDelegate alloc] init];
        dataSource = [[STRFullTableViewDataSource alloc] init];
        dataSource.rowsForEachSection = @[@3, @3];
        
        tableView.dataSource = dataSource;
        tableView.delegate = delegate;
        
        [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCellReuseIdentifier"];

        fakePlacementKey = @"fake-placement-key";
        fakeAdCache = nice_fake_for([STRAdCache class]);
        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterInSection:1 articlesBeforeFirstAd:1 articlesBetweenAds:100 placementKey:fakePlacementKey adCache:fakeAdCache];
        spy_on(adPlacementAdjuster);
        
        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];
        
        [injector bind:[STRAdGenerator class] toInstance:[STRFakeAdGenerator new]];
        
        spy_on([STRAdPlacementAdjuster class]);
        [STRAdPlacementAdjuster class] stub_method(@selector(adjusterInSection:articlesBeforeFirstAd:articlesBetweenAds:placementKey:adCache:)).and_return(adPlacementAdjuster);
        
        dataSourceProxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"adCellReuseIdentifier"
                                                                                   placementKey:@"placementKey"
                                                                       presentingViewController:nil
                                                                                       injector:injector];
        dataSourceProxy.originalDataSource = dataSource;
        dataSourceProxy.adjuster = adPlacementAdjuster;
        
        tableViewAdGenerator = [injector getInstance:[STRGridlikeViewAdGenerator class]];
        
        [tableViewAdGenerator placeAdInGridlikeView:tableView
                         dataSourceProxy:dataSourceProxy
                   adCellReuseIdentifier:@"adCellReuseIdentifier"
                            placementKey:@"placementKey"
                presentingViewController:nil
                                  adSize:CGSizeZero
                              articlesBeforeFirstAd:1
                                 articlesBetweenAds:100
                                          adSection:1];
        
        [tableView reloadData];
    });
    
    describe(@"when an ad is loaded", ^{
        beforeEach(^{
            fakeAdCache stub_method(@selector(numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:)).and_return((long)1);
            fakeAdCache stub_method(@selector(assignedAdIndixesForPlacementKey:)).and_return(@[[NSNumber numberWithInt:1]]);
            fakeAdCache stub_method(@selector(isAdAvailableForPlacement:)).and_return(YES);
            [tableView reloadData];
        });
        
        describe(@"-str_insertRowsAtIndexPaths:withAnimation:", ^{
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
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });

            describe(@"inserting rows in a table with an ad", ^{
                __block NSInteger originalRowCount;

                beforeEach(^{
                    spy_on(tableView);
                    dataSource.rowsForEachSection = @[@3, @6];
                    originalRowCount = [tableView numberOfRowsInSection:1];
                    [tableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
                });

                it(@"tells the table view to insert the rows at the correct index paths", ^{
                    tableView should have_received(@selector(insertRowsAtIndexPaths:withRowAnimation:));//.with(trueIndexPaths, UITableViewRowAnimationAutomatic);
                    [tableView numberOfRowsInSection:1] should equal(originalRowCount + 3);
                });
            });
        });

        describe(@"-str_deleteRowsAtIndexPaths:withRowAnimation:", ^{
            __block NSArray *externalIndexPaths;
            __block NSArray *trueIndexPaths;

            beforeEach(^{
                externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1],
                                       [NSIndexPath indexPathForRow:1 inSection:1]];
                trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1],
                                   [NSIndexPath indexPathForRow:2 inSection:1]];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_deleteRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });
            
            describe(@"deleting rows in a table with an ad", ^{
                __block NSInteger originalRowCount;
                
                beforeEach(^{
                    spy_on(tableView);
                    originalRowCount = tableView.visibleCells.count;
                    dataSource.rowsForEachSection = @[@3, @1];
                    [tableView str_deleteRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
                });
                
                it(@"tells the tableview to delete the correct rows", ^{
                    tableView should have_received(@selector(deleteRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, Arguments::anything);
                    tableView.visibleCells.count should equal(originalRowCount - 2);
                });
            });
        });

        describe(@"-str_moveRowAtIndexPath:toIndexPath:", ^{
            __block NSIndexPath *externalStartIndexPath;
            __block NSIndexPath *externalEndIndexPath;
            
            beforeEach(^{
                externalStartIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
                externalEndIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_moveRowAtIndexPath:externalStartIndexPath toIndexPath:externalEndIndexPath];
            });
            
            describe(@"moving rows in a table with an ad", ^{
                __block NSInteger originalRowCount;
                
                beforeEach(^{
                    spy_on(tableView);
                    originalRowCount = tableView.visibleCells.count;
                    [tableView str_moveRowAtIndexPath:externalStartIndexPath toIndexPath:externalEndIndexPath];
                });
                
                it(@"tells the tableview to move the correct rows", ^{
                    tableView should have_received(@selector(moveRowAtIndexPath:toIndexPath:));//.with([NSIndexPath indexPathForRow:3 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1]);
                    tableView.visibleCells.count should equal(originalRowCount);
                });
                
                it(@"updates the index path of the adPlacementAdjuster", ^{
                    adPlacementAdjuster should have_received(@selector(willMoveRowAtExternalIndexPath:toExternalIndexPath:)).with(externalStartIndexPath, externalEndIndexPath);
                });
            });
        });

        describe(@"-str_insertSections:withRowAnimation:", ^{
            __block NSIndexSet *sectionsToInsert;
            
            beforeEach(^{
                sectionsToInsert = [NSIndexSet indexSetWithIndex:0];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationNone];
            });
            
            describe(@"deleting sections in a table with an ad", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 3;
                    dataSource.rowsForEachSection = @[@3, @3, @3];
                    [tableView str_insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationNone];
                });
                
                it(@"passes the sections through to the table view's original method", ^{
                    tableView should have_received(@selector(insertSections:withRowAnimation:)).with([NSIndexSet indexSetWithIndex:0], UITableViewRowAnimationNone);
                });
                
                it(@"updates the ad's index path if necessary", ^{
                    adPlacementAdjuster should have_received(@selector(willInsertSections:)).with(sectionsToInsert);
                });
            });
        });

        describe(@"-str_deleteSections:withRowAnimation:", ^{
            __block NSIndexSet *sectionsToDelete;
            
            beforeEach(^{
                sectionsToDelete = [NSIndexSet indexSetWithIndex:0];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_deleteSections:sectionsToDelete withRowAnimation:UITableViewRowAnimationNone];
            });
            
            describe(@"deleting sections in a table with an ad", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 1;
                    [tableView str_deleteSections:sectionsToDelete withRowAnimation:UITableViewRowAnimationNone];
                });
                
                it(@"passes the sections through to the table view's original method", ^{
                    tableView should have_received(@selector(deleteSections:withRowAnimation:)).with([NSIndexSet indexSetWithIndex:0], UITableViewRowAnimationNone);
                });
                
                it(@"updates the ad's index path if necessary", ^{
                    adPlacementAdjuster should have_received(@selector(willDeleteSections:)).with(sectionsToDelete);
                    adPlacementAdjuster.adSection should equal(0);
                });
            });
        });

        describe(@"-str_moveSection:toSection:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_moveSection:1 toSection:0];
            });
            
            describe(@"moving sections in a table with an ad", ^{
                beforeEach(^{
                    [tableView str_moveSection:1 toSection:0];
                });
                
                it(@"passes the sections through to the table view's original method", ^{
                    tableView should have_received(@selector(moveSection:toSection:)).with(1, 0);
                });
                
                it(@"updates the ad's index path if necessary", ^{
                    adPlacementAdjuster should have_received(@selector(willMoveSection:toSection:)).with(1, 0);
                    adPlacementAdjuster.adSection should equal(0);
                });
            });
        });

        describe(@"-str_reloadData", ^{
//            MMM - don't need to to throw exceptions with infinite scroll architecture
//            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
//                [noAdTableView str_reloadData];
//            });
            
            it(@"reloads the tableview, inserting a row at the new index path", ^{
                [(id<CedarDouble>)tableView reset_sent_messages];
                [tableView str_reloadData];
                
                tableView should have_received(@selector(reloadData));
                [tableView layoutIfNeeded]; // ?
                
                [tableView numberOfRowsInSection:0] should equal(3);
                [tableView numberOfRowsInSection:1] should equal(4);
                
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_instance_of([STRTableViewCell class]);
            });
            
            it(@"allows a nil default", ^{
                spy_on(tableViewAdGenerator);
                [(id<CedarDouble>)tableView reset_sent_messages];
                [tableView str_reloadData];
                
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_instance_of([STRTableViewCell class]);
            });
        });
        
        describe(@"-str_reloadRowsAtIndexPaths:withRowAnimation:", ^{
//            MMM - don't need to to throw exceptions with infinite scroll architecture
//            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
//                [noAdTableView str_reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
//            });
            
            it(@"reloads those adjusted rows", ^{
                [tableView str_reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1]]
                                     withRowAnimation:UITableViewRowAnimationLeft];
                
                tableView should have_received(@selector(reloadRowsAtIndexPaths:withRowAnimation:))
                .with(@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1], [NSIndexPath indexPathForRow:3 inSection:1]], UITableViewRowAnimationLeft);
            });
        });

        describe(@"-str_reloadSections:withRowAnimation:", ^{
//            MMM - don't need to to throw exceptions with infinite scroll architecture
//            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
//                [noAdTableView str_reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
//            });
            
            context(@"when the new section size is larger than ad position", ^{
                it(@"the ad remains in the same indexpath", ^{
                    dataSource.rowsForEachSection = @[@1, @1];
                    
                    [tableView str_reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationMiddle];
                    
                    tableView should have_received(@selector(reloadSections:withRowAnimation:))
                    .with([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)], UITableViewRowAnimationMiddle);
                    
                    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_instance_of([STRTableViewCell class]);
                });
            });
            
            context(@"when the new section size is smaller than ad position", ^{
                it(@"does not show an ad", ^{
                    dataSource.rowsForEachSection = @[@1, @0];
                    
                    [tableView str_reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationMiddle];
                    
                    tableView should have_received(@selector(reloadSections:withRowAnimation:))
                    .with([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)], UITableViewRowAnimationMiddle);
                    
                    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] should be_nil;
                });
            });
            
        });

        describe(@"-str_cellForRowAtIndexPath:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });
            
            it(@"returns the cell adjusted from the external index path", ^{
                UITableViewCell *returnedCell = [tableView str_cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                
                tableView should have_received(@selector(cellForRowAtIndexPath:)).with([NSIndexPath indexPathForRow:2 inSection:1]);
                returnedCell should be_instance_of([UITableViewCell class]);
            });
        });
        
        describe(@"-str_indexPathForCell:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathForCell:[tableView.visibleCells firstObject]];
            });
            
            it(@"returns an adjusted index path if not an ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[5];
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForCell:cell];
                
                tableView should have_received(@selector(indexPathForCell:)).with(cell);
                returnedIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
            });
            
            it(@"returns nil if the cell passed in is an ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[4];
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForCell:cell];
                
                tableView should have_received(@selector(indexPathForCell:)).with(cell);
                returnedIndexPath should be_nil;
            });
            
            it(@"returns nil if the cell passed in is nil", ^{
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForCell:nil];
                
                tableView should have_received(@selector(indexPathForCell:)).with(nil);
                returnedIndexPath should be_nil;
            });
        });

        describe(@"-str_indexPathForRowAtPoint:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathForRowAtPoint:CGPointMake(0, 0)];
            });
            
            it(@"returns an adjusted index path if not a point within ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[5];
                
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForRowAtPoint:cell.center];
                
                tableView should have_received(@selector(indexPathForRowAtPoint:)).with(cell.center);
                returnedIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
            });
            
            it(@"returns nil if the point passed in is within an ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[4];
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForRowAtPoint:cell.center];
                
                tableView should have_received(@selector(indexPathForRowAtPoint:)).with(cell.center);
                returnedIndexPath should be_nil;
            });
            
            it(@"returns nil if the point passed in is out of bounds", ^{
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForRowAtPoint:CGPointMake(-1, -1)];
                
                tableView should have_received(@selector(indexPathForRowAtPoint:)).with(CGPointMake(-1, -1));
                returnedIndexPath should be_nil;
            });
        });
        
        describe(@"-str_indexPathsForRowsInRect:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathsForRowsInRect:CGRectMake(0, 0, 10, 10)];
            });
            
            it(@"returns an array of adjusted index paths without the ad cell", ^{
                CGRect rect = [tableView rectForSection:1];
                NSArray *returnedIndexPaths = [tableView str_indexPathsForRowsInRect:rect];
                
                tableView should have_received(@selector(indexPathsForRowsInRect:)).with(rect);
                returnedIndexPaths should equal(@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                  [NSIndexPath indexPathForRow:1 inSection:1],
                                                  [NSIndexPath indexPathForRow:2 inSection:1]]);
            });
        });

        describe(@"-str_visibleCells", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_visibleCellsWithoutAds];
            });
            
            it(@"returns an array of UITableViewCells without the ad cell", ^{
                [tableView.visibleCells count] should equal(7);
                NSArray *returnedVisibleCells = [tableView str_visibleCellsWithoutAds];
                
                tableView should have_received(@selector(visibleCells));
                [returnedVisibleCells count] should equal(6);
                for (UITableViewCell *cell in returnedVisibleCells) {
                    cell should be_instance_of([UITableViewCell class]);
                }
            });
        });

        describe(@"-str_indexPathsForVisibleRows", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathsForVisibleRows];
            });
            
            it(@"returns an array of NSIndexPaths without the ad cell", ^{
                tableView.frame = [tableView rectForSection:1];
                [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                [tableView.visibleCells count] should equal(4);
                NSArray *returnedIndexPaths = [tableView str_indexPathsForVisibleRows];
                
                tableView should have_received(@selector(indexPathsForVisibleRows));
                [returnedIndexPaths count] should equal(3);
                returnedIndexPaths should equal(@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                  [NSIndexPath indexPathForRow:1 inSection:1],
                                                  [NSIndexPath indexPathForRow:2 inSection:1]]);
            });
        });

        describe(@"-str_rectForRowAtIndexPath:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });
            
            it(@"returns a rect for row at index path", ^{
                CGRect returnedRect = [tableView str_rectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                
                returnedRect should equal([tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:1]]);
            });
        });
        
        describe(@"-str_numberOfRowsInSection:", ^{
            context(@"when the section contains an ad", ^{
                it(@"returns the number of rows minus the ad", ^{
                    [tableView numberOfRowsInSection:1] should equal(4);
                    [(id<CedarDouble>)tableView reset_sent_messages];
                    NSInteger numberOfRows = [tableView str_numberOfRowsInSection:1];

                    numberOfRows should equal(3);
                    tableView should have_received(@selector(numberOfRowsInSection:));
                });
            });

            context(@"when the section does not contain an ad", ^{
                it(@"returns the number of rows in the section", ^{
                    [tableView numberOfRowsInSection:0] should equal(3);

                    [(id<CedarDouble>)tableView reset_sent_messages];
                    NSInteger numberOfRows = [tableView str_numberOfRowsInSection:0];

                    numberOfRows should equal(3);
                    tableView should have_received(@selector(numberOfRowsInSection:));
                });
            });
        });

        describe(@"-str_indexPathForSelectedRow", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathForSelectedRow];
            });
            
            it(@"returns the adjusted index path for the selected row", ^{
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                
                [tableView str_indexPathForSelectedRow] should equal([NSIndexPath indexPathForRow:1 inSection:1]);
            });
        });
        
        describe(@"-str_indexPathsForSelectedRows", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathsForSelectedRows];
            });
            
            it(@"returns the adjusted index path for the selected rows", ^{
                tableView.allowsMultipleSelection = YES;
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                
                [tableView str_indexPathsForSelectedRows] should equal(@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                                         [NSIndexPath indexPathForRow:1 inSection:1]]);
            });
        });

        describe(@"-str_selectRowAtIndexPath:animated:scrollPosition:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            });
            
            it(@"selects the adjusted row", ^{
                [tableView str_selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                tableView should have_received(@selector(selectRowAtIndexPath:animated:scrollPosition:))
                .with([NSIndexPath indexPathForRow:2 inSection:1], NO, UITableViewScrollPositionTop);
                
                [tableView indexPathForSelectedRow] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
        });
        
        describe(@"-str_deselectRowAtIndexPath:animated:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES];
            });
            
            it(@"deselects the adjusted row", ^{
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                
                [tableView str_deselectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] animated:NO];
                tableView should have_received(@selector(deselectRowAtIndexPath:animated:)).with([NSIndexPath indexPathForRow:2 inSection:1], NO);
                [tableView indexPathForSelectedRow] should be_nil;
            });
        });

        describe(@"-str_scrollToRowAtIndexPath:atScrollPosition:animated:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            });

            it(@"scrolls to the adjusted index path", ^{
                tableView.frame = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                
                [tableView str_scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                NSIndexPath *trueIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
                tableView should have_received(@selector(scrollToRowAtIndexPath:atScrollPosition:animated:)).with(trueIndexPath, UITableViewScrollPositionTop, NO);
                tableView.contentOffset should equal([tableView rectForRowAtIndexPath:trueIndexPath].origin);
            });
        });

        describe(@"-str_dataSource", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_dataSource];
            });
            
            it(@"returns the original data source", ^{
                [tableView str_dataSource] should be_same_instance_as(dataSource);
            });
        });
        
        describe(@"-str_setDataSource:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_setDataSource:nil];
            });
            
            it(@"sets the tableview datasource", ^{
                id<UITableViewDataSource> newDataSource = nice_fake_for(@protocol(UITableViewDataSource));
                
                [tableView str_setDataSource:newDataSource];
                tableView.str_dataSource should be_same_instance_as(newDataSource);
            });
        });
        
        describe(@"-str_delegate", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_delegate];
            });
            
            it(@"returns the original delegate", ^{
                [tableView str_delegate] should be_same_instance_as(delegate);
            });
        });
        
        describe(@"-str_setDelegate:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_setDelegate:nil];
            });
            
            it(@"sets the tableview delegate", ^{
                id<UITableViewDelegate> newDelegate = nice_fake_for(@protocol(UITableViewDelegate));
                
                // suppress deprecated method warning
                newDelegate reject_method(@selector(tableView:accessoryTypeForRowWithIndexPath:));
                
                [tableView str_setDelegate:newDelegate];
                tableView.str_delegate should be_same_instance_as(newDelegate);
            });
        });
    });
    
    describe(@"when an ad is not loaded", ^{
        
        beforeEach(^{
            [tableView reloadData];
        });
        
        describe(@"-str_insertRowsAtIndexPaths:withAnimation:", ^{
            __block NSArray *externalIndexPaths;
            __block NSArray *trueIndexPaths;
            
            beforeEach(^{
                externalIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:1],
                                       [NSIndexPath indexPathForRow:0 inSection:1],
                                       [NSIndexPath indexPathForRow:4 inSection:1]];
                trueIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:1],
                                   [NSIndexPath indexPathForRow:0 inSection:1],
                                   [NSIndexPath indexPathForRow:4 inSection:1]];
            });
          
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });
          
            describe(@"inserting rows in a table with an ad", ^{
                __block NSInteger originalRowCount;
                
                beforeEach(^{
                    spy_on(tableView);
                    originalRowCount = tableView.visibleCells.count;
                    dataSource.rowsForEachSection = @[@3, @6];
                    [tableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
                });
                
                it(@"tells the table view to insert the rows at the correct index paths", ^{
                    tableView should have_received(@selector(insertRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, UITableViewRowAnimationAutomatic);
                    
                    tableView.visibleCells.count should equal(originalRowCount + 3);
                });
            });
           
        });
        
        describe(@"-str_deleteRowsAtIndexPaths:withRowAnimation:", ^{
            __block NSArray *externalIndexPaths;
            __block NSArray *trueIndexPaths;
            
            beforeEach(^{
                externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1],
                                       [NSIndexPath indexPathForRow:1 inSection:1]];
                trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:1],
                                   [NSIndexPath indexPathForRow:1 inSection:1]];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_deleteRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });
            
            describe(@"deleting rows in a table with an ad", ^{
                __block NSInteger originalRowCount;
                
                beforeEach(^{
                    spy_on(tableView);
                    originalRowCount = tableView.visibleCells.count;
                    dataSource.rowsForEachSection = @[@3, @1];
                    [tableView str_deleteRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
                });
                
                it(@"tells the tableview to delete the correct rows", ^{
                    tableView should have_received(@selector(deleteRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, Arguments::anything);
                    tableView.visibleCells.count should equal(originalRowCount - 2);
                });
            });
        });
        
        describe(@"-str_moveRowAtIndexPath:toIndexPath:", ^{
            __block NSIndexPath *externalStartIndexPath;
            __block NSIndexPath *externalEndIndexPath;
            
            beforeEach(^{
                externalStartIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
                externalEndIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_moveRowAtIndexPath:externalStartIndexPath toIndexPath:externalEndIndexPath];
            });
            
            describe(@"moving rows in a table with an ad", ^{
                __block NSInteger originalRowCount;
                
                beforeEach(^{
                    spy_on(tableView);
                    originalRowCount = tableView.visibleCells.count;
                    [tableView str_moveRowAtIndexPath:externalStartIndexPath toIndexPath:externalEndIndexPath];
                });
                
                it(@"tells the tableview to move the correct rows", ^{
                    tableView should have_received(@selector(moveRowAtIndexPath:toIndexPath:)).with([NSIndexPath indexPathForRow:2 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1]);
                    tableView.visibleCells.count should equal(originalRowCount);
                });
                
                it(@"updates the index path of the adPlacementAdjuster", ^{
                    adPlacementAdjuster should have_received(@selector(willMoveRowAtExternalIndexPath:toExternalIndexPath:)).with(externalStartIndexPath, externalEndIndexPath);
                    adPlacementAdjuster.adSection should equal(1);
                });
            });
        });
        
        describe(@"-str_insertSections:withRowAnimation:", ^{
            __block NSIndexSet *sectionsToInsert;
            
            beforeEach(^{
                sectionsToInsert = [NSIndexSet indexSetWithIndex:0];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationNone];
            });
            
            describe(@"deleting sections in a table with an ad", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 3;
                    dataSource.rowsForEachSection = @[@3, @3, @3];
                    [tableView str_insertSections:sectionsToInsert withRowAnimation:UITableViewRowAnimationNone];
                });
                
                it(@"passes the sections through to the table view's original method", ^{
                    tableView should have_received(@selector(insertSections:withRowAnimation:)).with([NSIndexSet indexSetWithIndex:0], UITableViewRowAnimationNone);
                });
                
                it(@"updates the ad's index path if necessary", ^{
                    adPlacementAdjuster should have_received(@selector(willInsertSections:)).with(sectionsToInsert);
                    adPlacementAdjuster.adSection should equal(2);
                });
            });
        });
        
        describe(@"-str_deleteSections:withRowAnimation:", ^{
            __block NSIndexSet *sectionsToDelete;
            
            beforeEach(^{
                sectionsToDelete = [NSIndexSet indexSetWithIndex:0];
            });
            
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_deleteSections:sectionsToDelete withRowAnimation:UITableViewRowAnimationNone];
            });
            
            describe(@"deleting sections in a table with an ad", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 1;
                    [tableView str_deleteSections:sectionsToDelete withRowAnimation:UITableViewRowAnimationNone];
                });
                
                it(@"passes the sections through to the table view's original method", ^{
                    tableView should have_received(@selector(deleteSections:withRowAnimation:)).with([NSIndexSet indexSetWithIndex:0], UITableViewRowAnimationNone);
                });
                
                it(@"updates the ad's index path if necessary", ^{
                    adPlacementAdjuster should have_received(@selector(willDeleteSections:)).with(sectionsToDelete);
                    adPlacementAdjuster.adSection should equal(0);
                });
            });
        });
        
        describe(@"-str_moveSection:toSection:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_moveSection:1 toSection:0];
            });
            
            describe(@"moving sections in a table with an ad", ^{
                beforeEach(^{
                    [tableView str_moveSection:1 toSection:0];
                });
                
                it(@"passes the sections through to the table view's original method", ^{
                    tableView should have_received(@selector(moveSection:toSection:)).with(1, 0);
                });
                
                it(@"updates the ad's index path if necessary", ^{
                    adPlacementAdjuster should have_received(@selector(willMoveSection:toSection:)).with(1, 0);
                    adPlacementAdjuster.adSection should equal(0);
                });
            });
        });
        
        describe(@"-str_reloadData", ^{
//            MMM - don't need to to throw exceptions with infinite scroll architecture
//            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
//                [noAdTableView str_reloadData];
//            });
            
            it(@"reloads the tableview, inserting a row at the new index path", ^{
                [(id<CedarDouble>)tableView reset_sent_messages];
                [tableView str_reloadData];
                
                tableView should have_received(@selector(reloadData));
                [tableView layoutIfNeeded]; // ?
                
                [tableView numberOfRowsInSection:0] should equal(3);
                [tableView numberOfRowsInSection:1] should equal(3);
                
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should be_instance_of([UITableViewCell class]);
            });
            
            it(@"allows a nil default", ^{
                spy_on(tableViewAdGenerator);
                [(id<CedarDouble>)tableView reset_sent_messages];
                [tableView str_reloadData];
                
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_instance_of([UITableViewCell class]);
            });
        });
        
        describe(@"-str_reloadRowsAtIndexPaths:withRowAnimation:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
            });
            
            it(@"reloads those adjusted rows", ^{
                [tableView str_reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1]]
                                     withRowAnimation:UITableViewRowAnimationLeft];
                
                tableView should have_received(@selector(reloadRowsAtIndexPaths:withRowAnimation:))
                .with(@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:2 inSection:1]], UITableViewRowAnimationLeft);
            });
        });
        
        describe(@"-str_reloadSections:withRowAnimation:", ^{
//            MMM - don't need to to throw exceptions with infinite scroll architecture
//            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
//                [noAdTableView str_reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle];
//            });
            
            context(@"when the new section size is larger than ad position", ^{
                it(@"the ad remains in the same indexpath", ^{
                    dataSource.rowsForEachSection = @[@1, @1];
                    
                    [tableView str_reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationMiddle];
                    
                    tableView should have_received(@selector(reloadSections:withRowAnimation:))
                    .with([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)], UITableViewRowAnimationMiddle);
                    
                    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_nil;
                });
            });
            
            context(@"when the new section size is smaller than ad position", ^{
                it(@"adjusts the ad to be bottom-most in the section", ^{
                    dataSource.rowsForEachSection = @[@1, @0];
                    
                    [tableView str_reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationMiddle];
                    
                    tableView should have_received(@selector(reloadSections:withRowAnimation:))
                    .with([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)], UITableViewRowAnimationMiddle);
                    
                    [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] should be_nil;
                });
            });
        });
        
        describe(@"-str_cellForRowAtIndexPath:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });
            
            it(@"returns the cell adjusted from the external index path", ^{
                UITableViewCell *returnedCell = [tableView str_cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                
                tableView should have_received(@selector(cellForRowAtIndexPath:)).with([NSIndexPath indexPathForRow:1 inSection:1]);
                returnedCell should be_instance_of([UITableViewCell class]);
            });
        });
        
        describe(@"-str_indexPathForCell:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathForCell:[tableView.visibleCells firstObject]];
            });
            
            it(@"returns an adjusted index path if not an ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[5];
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForCell:cell];
                
                tableView should have_received(@selector(indexPathForCell:)).with(cell);
                returnedIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if the cell passed in is an ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[4];
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForCell:cell];
                
                tableView should have_received(@selector(indexPathForCell:)).with(cell);
                returnedIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
            });
            
            it(@"returns nil if the cell passed in is nil", ^{
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForCell:nil];
                
                tableView should have_received(@selector(indexPathForCell:)).with(nil);
                returnedIndexPath should be_nil;
            });
        });
        
        describe(@"-str_indexPathForRowAtPoint:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathForRowAtPoint:CGPointMake(0, 0)];
            });
            
            it(@"returns an adjusted index path if not a point within ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[5];
                
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForRowAtPoint:cell.center];
                
                tableView should have_received(@selector(indexPathForRowAtPoint:)).with(cell.center);
                returnedIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if the point passed in is within an ad cell", ^{
                UITableViewCell *cell = tableView.visibleCells[4];
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForRowAtPoint:cell.center];
                
                tableView should have_received(@selector(indexPathForRowAtPoint:)).with(cell.center);
                returnedIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
            });
            
            it(@"returns nil if the point passed in is out of bounds", ^{
                NSIndexPath *returnedIndexPath = [tableView str_indexPathForRowAtPoint:CGPointMake(-1, -1)];
                
                tableView should have_received(@selector(indexPathForRowAtPoint:)).with(CGPointMake(-1, -1));
                returnedIndexPath should be_nil;
            });
        });
        
        describe(@"-str_indexPathsForRowsInRect:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathsForRowsInRect:CGRectMake(0, 0, 10, 10)];
            });
            
            it(@"returns an array of adjusted index paths without the ad cell", ^{
                CGRect rect = [tableView rectForSection:1];
                NSArray *returnedIndexPaths = [tableView str_indexPathsForRowsInRect:rect];
                
                tableView should have_received(@selector(indexPathsForRowsInRect:)).with(rect);
                returnedIndexPaths should equal(@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                  [NSIndexPath indexPathForRow:1 inSection:1],
                                                  [NSIndexPath indexPathForRow:2 inSection:1]]);
            });
        });
        
        describe(@"-str_visibleCells", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_visibleCellsWithoutAds];
            });
            
            it(@"returns an array of UITableViewCells without the ad cell", ^{
                [tableView.visibleCells count] should equal(6);
                NSArray *returnedVisibleCells = [tableView str_visibleCellsWithoutAds];
                
                tableView should have_received(@selector(visibleCells));
                [returnedVisibleCells count] should equal(6);
                for (UITableViewCell *cell in returnedVisibleCells) {
                    cell should be_instance_of([UITableViewCell class]);
                }
            });
        });
        
        describe(@"-str_indexPathsForVisibleRows", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathsForVisibleRows];
            });
            
            it(@"returns an array of NSIndexPaths without the ad cell", ^{
                tableView.frame = [tableView rectForSection:1];
                [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                [tableView.visibleCells count] should equal(3);
                NSArray *returnedIndexPaths = [tableView str_indexPathsForVisibleRows];
                
                tableView should have_received(@selector(indexPathsForVisibleRows));
                [returnedIndexPaths count] should equal(3);
                returnedIndexPaths should equal(@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                  [NSIndexPath indexPathForRow:1 inSection:1],
                                                  [NSIndexPath indexPathForRow:2 inSection:1]]);
            });
        });
        
        describe(@"-str_rectForRowAtIndexPath:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            });
            
            it(@"returns a rect for row at index path", ^{
                CGRect returnedRect = [tableView str_rectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                
                returnedRect should equal([tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]]);
            });
        });
        
        describe(@"-str_numberOfRowsInSection:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_numberOfRowsInSection:0];
            });
            
            context(@"when the section contains an ad", ^{
                it(@"returns the number of rows minus the ad", ^{
                    [tableView numberOfRowsInSection:1] should equal(3);
                    
                    [(id<CedarDouble>)tableView reset_sent_messages];
                    NSInteger numberOfRows = [tableView str_numberOfRowsInSection:1];
                    
                    numberOfRows should equal(3);
                    tableView should have_received(@selector(numberOfRowsInSection:));
                });
            });
            
            context(@"when the section does not contain an ad", ^{
                it(@"returns the number of rows in the section", ^{
                    [tableView numberOfRowsInSection:0] should equal(3);
                    
                    [(id<CedarDouble>)tableView reset_sent_messages];
                    NSInteger numberOfRows = [tableView str_numberOfRowsInSection:0];
                    
                    numberOfRows should equal(3);
                    tableView should have_received(@selector(numberOfRowsInSection:));
                });
            });
        });
        
        describe(@"-str_indexPathForSelectedRow", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathForSelectedRow];
            });
            
            it(@"returns the adjusted index path for the selected row", ^{
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                
                [tableView str_indexPathForSelectedRow] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
        });
        
        describe(@"-str_indexPathsForSelectedRows", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_indexPathsForSelectedRows];
            });
            
            it(@"returns the adjusted index path for the selected rows", ^{
                tableView.allowsMultipleSelection = YES;
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                
                [tableView str_indexPathsForSelectedRows] should equal(@[[NSIndexPath indexPathForRow:0 inSection:1],
                                                                         [NSIndexPath indexPathForRow:2 inSection:1]]);
            });
        });

        describe(@"-str_selectRowAtIndexPath:animated:scrollPosition:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
            });
            
            it(@"selects the adjusted row", ^{
                [tableView str_selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                tableView should have_received(@selector(selectRowAtIndexPath:animated:scrollPosition:))
                .with([NSIndexPath indexPathForRow:1 inSection:1], NO, UITableViewScrollPositionTop);
                
                [tableView indexPathForSelectedRow] should equal([NSIndexPath indexPathForRow:1 inSection:1]);
            });
        });
        
        describe(@"-str_deselectRowAtIndexPath:animated:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES];
            });
            
            it(@"deselects the adjusted row", ^{
                [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionTop];
                
                [tableView str_deselectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO];
                tableView should have_received(@selector(deselectRowAtIndexPath:animated:)).with([NSIndexPath indexPathForRow:2 inSection:1], NO);
                [tableView indexPathForSelectedRow] should be_nil;
            });
        });
        
        describe(@"-str_scrollToRowAtIndexPath:atScrollPosition:animated:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            });
            
            it(@"scrolls to the adjusted index path", ^{
                tableView.frame = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                
                [tableView str_scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                NSIndexPath *trueIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
                tableView should have_received(@selector(scrollToRowAtIndexPath:atScrollPosition:animated:)).with(trueIndexPath, UITableViewScrollPositionTop, NO);
                tableView.contentOffset should equal([tableView rectForRowAtIndexPath:trueIndexPath].origin);
            });
            
            it(@"is able to scroll to NSNotFound", ^{
                tableView.frame = [tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                
                [tableView str_scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                tableView.contentOffset should equal([tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]].origin);
            });
        });
        
        describe(@"-str_dataSource", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_dataSource];
            });
            
            it(@"returns the original data source", ^{
                [tableView str_dataSource] should be_same_instance_as(dataSource);
            });
        });
        
        describe(@"-str_setDataSource:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_setDataSource:nil];
            });
            
            it(@"sets the tableview datasource", ^{
                id<UITableViewDataSource> newDataSource = nice_fake_for(@protocol(UITableViewDataSource));
                
                [tableView str_setDataSource:newDataSource];
                tableView.str_dataSource should be_same_instance_as(newDataSource);
            });
        });
        
        describe(@"-str_delegate", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_delegate];
            });
            
            it(@"returns the original delegate", ^{
                [tableView str_delegate] should be_same_instance_as(delegate);
            });
        });
        
        describe(@"-str_setDelegate:", ^{
            itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
                [noAdTableView str_setDelegate:nil];
            });
            
            it(@"sets the tableview delegate", ^{
                id<UITableViewDelegate> newDelegate = nice_fake_for(@protocol(UITableViewDelegate));
                
                // suppress deprecated method warning
                newDelegate reject_method(@selector(tableView:accessoryTypeForRowWithIndexPath:));
                
                [tableView str_setDelegate:newDelegate];
                tableView.str_delegate should be_same_instance_as(newDelegate);
            });
        });
    });
});

SPEC_END
