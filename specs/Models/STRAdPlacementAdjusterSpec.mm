#import "STRAdPlacementAdjuster.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdPlacementAdjusterSpec)

describe(@"STRAdPlacementAdjuster", ^{
    __block STRAdPlacementAdjuster *adjuster;

    beforeEach(^{
        UITableView *tableView = nice_fake_for([UITableView class]);
        tableView stub_method(@selector(numberOfRowsInSection:)).with(0).and_return(2);
        adjuster = [STRAdPlacementAdjuster adjusterWithInitialTableView:tableView];
    });

    describe(@"-isAdAtIndexPath:", ^{
        it(@"returns YES if indexPaths match", ^{
            [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_truthy;
        });

        it(@"returns NO if indexPaths match", ^{
            [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_falsy;
        });
    });

    describe(@"-externalIndexPath:", ^{
        it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
            [adjuster externalIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
        });

        it(@"raises exception if indexPath is equal to adIndexPath", ^{
            expect(^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];}).to(raise_exception());
        });

        it(@"subtracts indexPath for cells after ad row in same section", ^{
            [adjuster externalIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"leaves indexPath unchanged for cells in different section", ^{
            [adjuster externalIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
        });
    });

    describe(@"-trueIndexPath:", ^{
        it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
            [adjuster trueIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
        });

        it(@"increments indexPath if it's equal to adIndexPath", ^{
            [adjuster trueIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
        });

        it(@"increments indexPath for cells after ad row in same section", ^{
            [adjuster trueIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:3 inSection:0]);
        });

        it(@"leaves indexPath unchanged for cells in different section", ^{
            [adjuster trueIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
        });
    });

    describe(@"-willInsertRowsAtExternalIndexPaths:", ^{
        it(@"leaves adIndexPath unchanged if insertion is after adIndexPath", ^{
            [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"increments adIndexPath if insertions is before adIndexPath", ^{
            [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
        });

        it(@"increments adIndexPath if insertion is at adIndexPath", ^{
            [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
        });

        it(@"leaves adIndexPath unchanged for insertion in a different section", ^{
            [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"handles multiple indexPaths inserted and places the ad in the right place", ^{
            [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:0 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:3 inSection:0]);
        });
    });

    describe(@"-willDeleteRowsAtExternalIndexPaths:", ^{
        it(@"leaves adIndexPath unchanged if deletion is after adIndexPath", ^{
            [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"decrements adIndexPath if deletion is before adIndexPath", ^{
            [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
        });

        it(@"leaves adIndexPath unchanged if deletion is at adIndexPath", ^{
            [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"leaves adIndexPath unchanged for deletion in a different section", ^{
            [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"handles multiple indexPaths deleted and places the ad in the right place", ^{
            [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]]];
            adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
        });
    });
});

SPEC_END
