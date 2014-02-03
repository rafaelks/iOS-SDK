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

    describe(@"-str_insertRowAtIndexPath:withAnimation:", ^{
        __block NSInteger originalRowCount;
        __block NSIndexPath *indexPath;

        beforeEach(^{
            indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
        });

        describe(@"inserting a row in a table without an ad", ^{
            beforeEach(^{
                originalRowCount = noAdTableView.visibleCells.count;
                dataSource.rowsInEachSection++;
            });

            it(@"raises an exception", ^{
                expect(^{
                    [noAdTableView str_insertRowAtIndexPath:indexPath withAnimation:UITableViewRowAnimationAutomatic];
                }).to(raise_exception);

                noAdTableView.visibleCells.count should equal(originalRowCount);
            });
        });

        describe(@"inserting a row in a table with an ad", ^{
            beforeEach(^{
                spy_on(tableView);
                originalRowCount = tableView.visibleCells.count;
                dataSource.rowsInEachSection++;
                [tableView str_insertRowAtIndexPath:indexPath withAnimation:UITableViewRowAnimationAutomatic];
            });

            it(@"inserts the row into the tableview", ^{
                tableView.visibleCells.count should equal(originalRowCount + 1);
            });

            it(@"inserted row is adjusted for indexpath", ^{
                tableView should have_received(@selector(insertRowsAtIndexPaths:withRowAnimation:)).with(@[[NSIndexPath indexPathForRow:3 inSection:0]], Arguments::anything);
            });

            it(@"updates the index path of the adPlacementAdjuster", ^{
                adPlacementAdjuster should have_received(@selector(didInsertRowAtIndexPath:)).with(indexPath);
            });
        });
    });
});

SPEC_END
