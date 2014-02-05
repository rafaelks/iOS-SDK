#import "UITableView+STR.h"
#import "STRAdPlacementAdjuster.h"
#import "STRTableViewDataSource.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewDelegate.h"
#import "STRTableViewAdGenerator.h"
#import <objc/runtime.h>
#import "STRAdGenerator.h"
#import "STRAppModule.h"
#import "STRTableViewCell.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const STRTableViewAdGeneratorKey;

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

    beforeEach(^{
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
        delegate = [[STRTableViewDelegate alloc] init];
        dataSource = [[STRFullTableViewDataSource alloc] init];
        dataSource.rowsForEachSection = @[@3, @3];

        tableView.dataSource = dataSource;
        tableView.delegate = delegate;

        [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCellReuseIdentifier"];

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
        spy_on(adPlacementAdjuster);

        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        [injector bind:[STRAdGenerator class] toInstance:nice_fake_for([STRAdGenerator class])];

        spy_on([STRAdPlacementAdjuster class]);
        [STRAdPlacementAdjuster class] stub_method(@selector(adjusterWithInitialAdIndexPath:)).and_return(adPlacementAdjuster);

        STRTableViewAdGenerator *tableViewAdGenerator = [injector getInstance:[STRTableViewAdGenerator class]];
        [tableViewAdGenerator placeAdInTableView:tableView
                           adCellReuseIdentifier:@"adCellReuseIdentifier"
                                    placementKey:@"placementKey"
                        presentingViewController:nil
                                        adHeight:100.0];

        [tableView reloadData];
    });

    describe(@"-str_insertRowsAtIndexPaths:withAnimation:", ^{
        __block NSArray *externalIndexPaths;
        __block NSArray *trueIndexPaths;

        beforeEach(^{
            externalIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:1],
                           [NSIndexPath indexPathForRow:0 inSection:1],
                           [NSIndexPath indexPathForRow:3 inSection:1]];
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
                tableView should have_received(@selector(insertRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, Arguments::anything);

                tableView.visibleCells.count should equal(originalRowCount + 3);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willInsertRowsAtExternalIndexPaths:)).with(externalIndexPaths);
                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:3 inSection:1]);
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

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willDeleteRowsAtExternalIndexPaths:)).with(externalIndexPaths);

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:1]);
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

            it(@"tells the tableview to delete the correct rows", ^{
                tableView should have_received(@selector(moveRowAtIndexPath:toIndexPath:)).with([NSIndexPath indexPathForRow:3 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1]);
                tableView.visibleCells.count should equal(originalRowCount);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willMoveRowAtExternalIndexPath:toExternalIndexPath:)).with(externalStartIndexPath, externalEndIndexPath);

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
        });
    });

    describe(@"-str_insertSections:withRowAnimation:", ^{
        __block NSIndexSet *sectionsToInsert;

        beforeEach(^{
            spy_on(tableView);
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

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
            });
        });
    });

    describe(@"-str_deleteSections:withRowAnimation:", ^{
        __block NSIndexSet *sectionsToDelete;

        beforeEach(^{
            spy_on(tableView);
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

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
        });
    });

    describe(@"-str_moveSection:toSection:", ^{
        beforeEach(^{
            spy_on(tableView);
        });

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

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
        });
    });
});

SPEC_END
