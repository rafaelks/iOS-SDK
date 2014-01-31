#import "STRAdPlacementAdjuster.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdPlacementAdjusterSpec)

describe(@"STRAdPlacementAdjuster", ^{
    __block STRAdPlacementAdjuster *adjuster;

    beforeEach(^{
        adjuster = [STRAdPlacementAdjuster adjusterWithInitialIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    });

    describe(@"-isAdAtIndexPath:", ^{
        it(@"returns YES if indexPaths match", ^{
            [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_truthy;
        });

        it(@"returns NO if indexPaths match", ^{
            [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_falsy;
        });
    });

    describe(@"-adjustedIndexPath:", ^{
        it(@"leaves indexPath unchanged if it's above initialIndexPath", ^{
            [adjuster adjustedIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
        });

        it(@"leaves indexPath unchanged if it's equal to initialIndexPath", ^{
            expect(^{[adjuster adjustedIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];}).to(raise_exception());
        });

        it(@"subtracts indexPath for cells after ad row in same section", ^{
            [adjuster adjustedIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
        });

        it(@"leaves indexPath unchanged for cells in different section", ^{
            [adjuster adjustedIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
        });

    });
});

SPEC_END
