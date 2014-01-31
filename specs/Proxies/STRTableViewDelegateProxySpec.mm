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

    describe(@"one argument selectors that munge indexPath", ^{
        beforeEach(^{
            spy_on(adPlacementAdjuster);
        });

        context(@"when the index path is not the ad cell", ^{
            it(@"passes through tableView:accessoryButtonTappedForRowWithIndexPath: ", ^{
                [proxy tableView:tableView accessoryButtonTappedForRowWithIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            xit(@"passes through -tableView:accessoryTypeForRowWithIndexPath: ", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [proxy tableView:tableView accessoryTypeForRowWithIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
#pragma clang diagnostic pop
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:accessoryTypeForRowWithIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didSelectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:didSelectRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didDeselectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:didDeselectRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:willBeginEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:willBeginEditingRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didEndEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:didEndEditingRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didHighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didHighlightRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:didHighlightRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didUnhighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didUnhighlightRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:didUnhighlightRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });
        });

        context(@"when indexPath points to an ad index path", ^{
            it(@"prevents original delegate from receiving tableView:accessoryButtonTappedForRowWithIndexPath: ", ^{
                [proxy tableView:tableView accessoryButtonTappedForRowWithIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:));
            });

            xit(@"prevents original delegate from receiving -tableView:accessoryTypeForRowWithIndexPath: ", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [proxy tableView:tableView accessoryTypeForRowWithIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
#pragma clang diagnostic pop
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:accessoryTypeForRowWithIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didSelectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didSelectRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didDeselectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didDeselectRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:willBeginEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:willBeginEditingRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didEndEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didEndEditingRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didHighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didHighlightRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didHighlightRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didUnhighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didUnhighlightRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didUnhighlightRowAtIndexPath:));
            });
        });
    });

    describe(@"two argument selectors that munge indexPath", ^{
        __block UITableViewCell *tableCell;

        beforeEach(^{
            spy_on(adPlacementAdjuster);
            tableCell = [UITableViewCell new];
        });

        context(@"when the index path is not the ad cell", ^{
            it(@"passes through -tableView:willDisplayCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView willDisplayCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:willDisplayCell:forRowAtIndexPath:))
                .with(tableView, tableCell, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didEndDisplayingCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndDisplayingCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:))
                .with(tableView, tableCell, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:performAction:forRowAtIndexPath:withSender: ", ^{
                [proxy tableView:tableView performAction:@selector(count) forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] withSender:@[]];
                adPlacementAdjuster should have_received(@selector(adjustedIndexPath:));
                originalDelegate should have_received(@selector(tableView:performAction:forRowAtIndexPath:withSender:))
                .with(tableView, @selector(count), [NSIndexPath indexPathForRow:1 inSection:0], @[]);
            });
        });

        context(@"when the index path points to an ad index path", ^{
            it(@"prevents original delegate from receiving -tableView:willDisplayCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView willDisplayCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:willDisplayCell:forRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didEndDisplayingCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndDisplayingCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:));
            });


            it(@"prevents original delegate from receiving -tableView:performAction:forRowAtIndexPath:withSender: ", ^{
                [proxy tableView:tableView performAction:@selector(count) forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] withSender:@[]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(adjustedIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:performAction:forRowAtIndexPath:withSender:));
            });
        });
    });

    describe(@"height return value selectors that munge indexPaths", ^{
        describe(@"-tableView:heightForRowAtIndexPath:", ^{
            context(@"when the index path is not the ad cell", ^{
                it(@"offsets the index path and calls the original delegate", ^{
                    [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                    originalDelegate should have_received(@selector(tableView:heightForRowAtIndexPath:)).with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
                });
            });

            context(@"when the index path points to an ad index path", ^{
                it(@"does not call the delegate", ^{
                    [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                    originalDelegate should_not have_received(@selector(tableView:heightForRowAtIndexPath:));
                });

                it(@"returns a passed-in height value", ^{
                    [proxy tableView:tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(51.0);
                });
            });
        });

        describe(@"-tableView:estimatedHeightForRowAtIndexPath:", ^{
            context(@"when the index path is not the ad cell", ^{
                it(@"offsets the index path and calls the original delegate", ^{
                    [proxy tableView:tableView estimatedHeightForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                    originalDelegate should have_received(@selector(tableView:estimatedHeightForRowAtIndexPath:)).with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
                });
            });

            context(@"when the index path points to an ad index path", ^{
                it(@"does not call the delegate", ^{
                    [proxy tableView:tableView estimatedHeightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                    originalDelegate should_not have_received(@selector(tableView:estimatedHeightForRowAtIndexPath:));
                });

                it(@"returns a passed-in height value", ^{
                    [proxy tableView:tableView estimatedHeightForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(51.0);
                });
            });
        });
    });
});

SPEC_END
