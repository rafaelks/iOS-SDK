#import "UITableView+STR.h"
#import "STRAdPlacementAdjuster.h"
#import "STRTableViewDataSource.h"
#import "STRTableViewDelegate.h"
#import "STRTableViewAdGenerator.h"
#import <objc/runtime.h>
#import "STRAdGenerator.h"
#import "STRAppModule.h"
#import "STRTableViewCell.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const kTableViewAdGeneratorKey;

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
    __block STRTableViewDataSource *dataSource;
    __block STRAdPlacementAdjuster *adPlacementAdjuster;

    beforeEach(^{
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
        delegate = [[STRTableViewDelegate alloc] init];
        dataSource = [[STRTableViewDataSource alloc] init];
        dataSource.rowsInEachSection = 3;

        tableView.dataSource = dataSource;
        tableView.delegate = delegate;

        [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCellReuseIdentifier"];

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialTableView:tableView];
        spy_on(adPlacementAdjuster);

        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        [injector bind:[STRAdGenerator class] toInstance:nice_fake_for([STRAdGenerator class])];

        spy_on([STRAdPlacementAdjuster class]);
        [STRAdPlacementAdjuster class] stub_method(@selector(adjusterWithInitialTableView:)).and_return(adPlacementAdjuster);

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
            externalIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:0],
                           [NSIndexPath indexPathForRow:0 inSection:0],
                           [NSIndexPath indexPathForRow:3 inSection:0]];
            trueIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:0],
                               [NSIndexPath indexPathForRow:0 inSection:0],
                               [NSIndexPath indexPathForRow:4 inSection:0]];
        });

        itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
            [noAdTableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
        });

        describe(@"inserting rows in a table with an ad", ^{
            __block NSInteger originalRowCount;

            beforeEach(^{
                spy_on(tableView);
                originalRowCount = tableView.visibleCells.count;
                dataSource.rowsInEachSection += 3;
                [tableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });

            it(@"tells the table view to insert the rows at the correct index paths", ^{
                tableView should have_received(@selector(insertRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, Arguments::anything);

                tableView.visibleCells.count should equal(originalRowCount + 3);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willInsertRowsAtExternalIndexPaths:)).with(externalIndexPaths);
                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:3 inSection:0]);
            });
        });
    });

    describe(@"-str_deleteRowsAtIndexPaths:withRowAnimation:", ^{
        __block NSArray *externalIndexPaths;
        __block NSArray *trueIndexPaths;

        beforeEach(^{
            externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                   [NSIndexPath indexPathForRow:1 inSection:0]];
            trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                               [NSIndexPath indexPathForRow:2 inSection:0]];
        });

        itThrowsIfTableWasntConfigured(^(UITableView *noAdTableView) {
            [noAdTableView str_deleteRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
        });

        describe(@"deleting rows in a table with an ad", ^{
            __block NSInteger originalRowCount;

            beforeEach(^{
                spy_on(tableView);
                originalRowCount = tableView.visibleCells.count;
                dataSource.rowsInEachSection -= 2;
                [tableView str_deleteRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });

            it(@"tells the tableview to delete the correct rows", ^{
                tableView should have_received(@selector(deleteRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, Arguments::anything);
                tableView.visibleCells.count should equal(originalRowCount - 2);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(willDeleteRowsAtExternalIndexPaths:)).with(externalIndexPaths);

                adPlacementAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
        });
    });
});

SPEC_END
