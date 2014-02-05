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

    describe(@"-willMoveRowAtExternalIndexPath:toExternalIndexPath:", ^{
        __block STRAdPlacementAdjuster *multiSectionAdjuster;

        beforeEach(^{
            UITableView *tableView = nice_fake_for([UITableView class]);
            tableView stub_method(@selector(numberOfSections)).and_return(3);
            tableView stub_method(@selector(numberOfRowsInSection:)).and_return(2);
            multiSectionAdjuster = [STRAdPlacementAdjuster adjusterWithInitialTableView:tableView];
        });

        sharedExamplesFor(@"moving a row", ^(NSDictionary *sharedContext) {
            __block NSArray *trueIndexPaths;
            __block NSIndexPath *externalStartIndex;
            __block NSIndexPath *externalFinalIndex;
            __block NSIndexPath *initialAdIndex;

            beforeEach(^{
                externalStartIndex = sharedContext[@"externalStartIndex"];
                externalFinalIndex = sharedContext[@"externalFinalIndex"];
                initialAdIndex = multiSectionAdjuster.adIndexPath;
                trueIndexPaths = [multiSectionAdjuster willMoveRowAtExternalIndexPath:externalStartIndex
                                                                                    toExternalIndexPath:externalFinalIndex];
            });

            it(@"correctly adjusts the ad's index", ^{
                NSInteger row = [initialAdIndex row] + [sharedContext[@"expectedChangeToAdRow"] integerValue];

                NSIndexPath *expectedIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
                multiSectionAdjuster.adIndexPath should equal(expectedIndexPath);
            });

            it(@"returns the true index of the start position", ^{
                NSInteger startRow = externalStartIndex.row + [sharedContext[@"expectedChangeToStartRow"] integerValue];
                NSIndexPath *expectedStartPath = [NSIndexPath indexPathForRow:startRow inSection:externalStartIndex.section];

                [trueIndexPaths firstObject] should equal(expectedStartPath);

            });

            it(@"returns the true index of the end position", ^{
                NSInteger finalRow = externalFinalIndex.row + [sharedContext[@"expectedChangeToFinalRow"] integerValue];
                NSIndexPath *expectedFinalPath = [NSIndexPath indexPathForRow:finalRow inSection:externalFinalIndex.section];

                [trueIndexPaths lastObject] should equal(expectedFinalPath);
            });
        });

        describe(@"moving from an ad section to an ad section", ^{
            describe(@"(AFTER -> BEFORE) handles moving to an index path that is before an ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @1;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @1;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });

                itShouldBehaveLike(@"moving a row");
            });

            describe(@"(AFTER -> SAME AS AD) handles moving from an index path after an ad to an index path that is an ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @1;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @1;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });

                itShouldBehaveLike(@"moving a row");
            });

            describe(@"(BEFORE -> AFTER)handles moving from an index path before an ad to an index path that is after an ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @-1;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @0;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @1;
                });

                itShouldBehaveLike(@"moving a row");
            });

            describe(@"(AFTER -> AFTER) handles moving from an index path to an index path, when are both after the ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @0;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @1;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @1;
                });

                itShouldBehaveLike(@"moving a row");
            });

            describe(@"(BEFORE -> BEFORE) handles moving from an index path to an index path, when both are after the ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @0;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @0;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;

                    [multiSectionAdjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
                });

                itShouldBehaveLike(@"moving a row");
            });
        });

        describe(@"moving from an ad section to a non-ad section", ^{
            describe(@"(BEFORE -> NEW SECTION)moving from before the ad to another section", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @-1;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @0;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });

                itShouldBehaveLike(@"moving a row");
            });

            describe(@"(AFTER -> NEW SECTION)moving from after the ad to another section", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @0;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                    sharedContext[@"expectedChangeToStartRow"] = @1;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });

                itShouldBehaveLike(@"moving a row");
            });
        });

        describe(@"moving from a non-ad section to an ad section", ^{
            describe(@"(NON-AD SECTION -> BEFORE AD)moving from some section to the ad's section, before the ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @1;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:1];
                    sharedContext[@"expectedChangeToStartRow"] = @0;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });

                itShouldBehaveLike(@"moving a row");
            });

            describe(@"(NON-AD SECTION -> AFTER AD)moving from some section to the ad's section, after the ad", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @0;

                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:1];
                    sharedContext[@"expectedChangeToStartRow"] = @0;

                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                    sharedContext[@"expectedChangeToFinalRow"] = @1;
                });

                itShouldBehaveLike(@"moving a row");
            });

        });

        describe(@"moving from a non-ad section to a non-ad section", ^{
            beforeEach(^{
                NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                sharedContext[@"expectedChangeToAdRow"] = @0;

                sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                sharedContext[@"expectedChangeToStartRow"] = @0;

                sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:2];
                sharedContext[@"expectedChangeToFinalRow"] = @0;
            });

            itShouldBehaveLike(@"moving a row");
        });
    });

});

SPEC_END
