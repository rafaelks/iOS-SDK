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

describe(@"UITableView+STR", ^{
    __block UITableView *tableView;
    __block UITableView *noAdTableView;
    __block STRTableViewDelegate *delegate;
    __block STRTableViewDataSource *dataSource;
    __block STRAdPlacementAdjuster *adPlacementAdjuster;

    beforeEach(^{
        noAdTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];

        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 420)];
        delegate = [[STRTableViewDelegate alloc] init];
        dataSource = [[STRTableViewDataSource alloc] init];
        dataSource.rowsInEachSection = 3;

        tableView.dataSource = dataSource;
        tableView.delegate = delegate;
        noAdTableView.dataSource = dataSource;
        noAdTableView.delegate = delegate;

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

        [noAdTableView reloadData];
        [tableView reloadData];
    });

    describe(@"-str_insertRowsAtIndexPaths:withAnimation:", ^{
        __block NSInteger originalRowCount;
        __block NSArray *externalIndexPaths;
        __block NSArray *trueIndexPaths;

        beforeEach(^{
            externalIndexPaths = @[[NSIndexPath indexPathForRow:1 inSection:0],
                           [NSIndexPath indexPathForRow:0 inSection:0],
                           [NSIndexPath indexPathForRow:3 inSection:0]];
            trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                     [NSIndexPath indexPathForRow:1 inSection:0],
                                     [NSIndexPath indexPathForRow:4 inSection:0]];
        });

        describe(@"inserting a row in a table without an ad", ^{
            beforeEach(^{
                originalRowCount = noAdTableView.visibleCells.count;
                dataSource.rowsInEachSection++;
            });

            it(@"raises an exception", ^{
                expect(^{
                    [noAdTableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
                }).to(raise_exception);

                noAdTableView.visibleCells.count should equal(originalRowCount);
            });
        });

        describe(@"inserting a row in a table with an ad", ^{
            beforeEach(^{
                spy_on(tableView);
                originalRowCount = tableView.visibleCells.count;
                dataSource.rowsInEachSection += 3;
                [tableView str_insertRowsAtIndexPaths:externalIndexPaths withAnimation:UITableViewRowAnimationAutomatic];
            });

            it(@"inserts the row into the tableview", ^{
                tableView.visibleCells.count should equal(originalRowCount + 3);
            });

            it(@"inserted rows are adjusted for indexpath", ^{
                tableView should have_received(@selector(insertRowsAtIndexPaths:withRowAnimation:)).with(trueIndexPaths, Arguments::anything);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                for (NSIndexPath *path in trueIndexPaths) {
                    adPlacementAdjuster should have_received(@selector(didInsertRowAtTrueIndexPath:)).with(path);
                }
            });
        });

    });
});

SPEC_END
