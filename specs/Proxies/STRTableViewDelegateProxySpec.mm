#import "STRTableViewDelegateProxy.h"
#import "STRFullTableViewDelegate.h"
#import "STRAdPlacementAdjuster.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRTableViewDelegateProxySpec)

describe(@"STRTableViewDelegateProxy", ^{
    __block STRTableViewDelegateProxy *proxy;
    __block STRFullTableViewDelegate *originalDelegate;
    __block UITableView *tableView;
    __block STRAdPlacementAdjuster *adPlacementAdjuster;

    beforeEach(^{
        originalDelegate = [STRFullTableViewDelegate new];
        spy_on(originalDelegate);

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        tableView = [UITableView new];

        proxy = [[STRTableViewDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adPlacementAdjuster adHeight:51.0];
    });

    describe(@"-tableView:heightForRowAtIndexPath:", ^{
        context(@"when the index path is before the ad", ^{
            it(@"does not offset the index path before calling the original delegate", ^{
                [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                originalDelegate should have_received(@selector(tableView:heightForRowAtIndexPath:)).with(tableView, [NSIndexPath indexPathForRow:0 inSection:0]);
            });
        });

        context(@"when the index path is the ad", ^{
            it(@"does not call the delegate", ^{
                [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                originalDelegate should_not have_received(@selector(tableView:heightForRowAtIndexPath:));
            });

            it(@"returns a passed-in height value", ^{
                [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(51.0);
            });
        });

        context(@"when the index path is after the ad", ^{
            it(@"offsets the index path and calls the original delegate", ^{
                [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                originalDelegate should have_received(@selector(tableView:heightForRowAtIndexPath:)).with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });
        });
    });

    describe(@"selectors that pass through", ^{
        it(@"passes through -tableView:viewForHeaderInSection:", ^{
            [proxy tableView:tableView viewForHeaderInSection:1];
            originalDelegate should have_received(@selector(tableView:viewForHeaderInSection:)).with(tableView, 1);
        });

        it(@"passes through -tableView:viewForFooterInSection:", ^{
            [proxy tableView:tableView viewForFooterInSection:1];
            originalDelegate should have_received(@selector(tableView:viewForFooterInSection:)).with(tableView, 1);
        });

        it(@"passes through -tableView:heightForHeaderInSection:", ^{
            [proxy tableView:tableView heightForHeaderInSection:1];
            originalDelegate should have_received(@selector(tableView:heightForHeaderInSection:)).with(tableView, 1);
        });

        it(@"passes through -tableView:heightForFooterInSection:", ^{
            [proxy tableView:tableView heightForFooterInSection:1];
            originalDelegate should have_received(@selector(tableView:heightForFooterInSection:)).with(tableView, 1);
        });

        it(@"passes through -tableView:estimatedHeightForHeaderInSection:", ^{
            [proxy tableView:tableView estimatedHeightForHeaderInSection:1];
            originalDelegate should have_received(@selector(tableView:estimatedHeightForHeaderInSection:)).with(tableView, 1);
        });

        it(@"passes through -tableView:estimatedHeightForFooterInSection:", ^{
            [proxy tableView:tableView estimatedHeightForFooterInSection:1];
            originalDelegate should have_received(@selector(tableView:estimatedHeightForFooterInSection:)).with(tableView, 1);
        });

        it(@"passes through -tableView:willDisplayHeaderView:forSection:", ^{
            UIView *view = [UIView new];
            [proxy tableView:tableView willDisplayHeaderView:view forSection:1];
            originalDelegate should have_received(@selector(tableView:willDisplayHeaderView:forSection:)).with(tableView, view, 1);
        });

        it(@"passes through -tableView:willDisplayFooterView:forSection:", ^{
            UIView *view = [UIView new];
            [proxy tableView:tableView willDisplayFooterView:view forSection:1];
            originalDelegate should have_received(@selector(tableView:willDisplayFooterView:forSection:)).with(tableView, view, 1);
        });

        it(@"passes through -tableView:didEndDisplayingHeaderView:forSection:", ^{
            UIView *view = [UIView new];
            [proxy tableView:tableView didEndDisplayingHeaderView:view forSection:1];
            originalDelegate should have_received(@selector(tableView:didEndDisplayingHeaderView:forSection:)).with(tableView, view, 1);
        });

        it(@"passes through -tableView:didEndDisplayingFooterView:forSection:", ^{
            UIView *view = [UIView new];
            [proxy tableView:tableView didEndDisplayingFooterView:view forSection:1];
            originalDelegate should have_received(@selector(tableView:didEndDisplayingFooterView:forSection:)).with(tableView, view, 1);
        });
    });
});

SPEC_END
