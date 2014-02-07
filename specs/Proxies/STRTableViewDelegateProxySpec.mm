#import "STRTableViewDelegateProxy.h"
#import "STRFullTableViewDelegate.h"
#import "STRAdPlacementAdjuster.h"
#import "STRTableViewDelegate.h"
#import <objc/objc-runtime.h>

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
        tableView = nice_fake_for([UITableView class]);
        tableView stub_method(@selector(numberOfRowsInSection:)).with(0).and_return(2);

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

        proxy = [[STRTableViewDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adPlacementAdjuster adHeight:51.0];
    });

    context(@"when using a complete delegate", ^{
        it(@"responds to selector", ^{
            [proxy respondsToSelector:@selector(tableView:viewForHeaderInSection:)] should be_truthy;
        });
    });

    context(@"when using an empty delegate", ^{
        __block STRTableViewDelegate *emptyDelegate;
        beforeEach(^{
            emptyDelegate = [STRTableViewDelegate new];
            spy_on(emptyDelegate);
            proxy = [[STRTableViewDelegateProxy alloc] initWithOriginalDelegate:emptyDelegate adPlacementAdjuster:adPlacementAdjuster adHeight:51.0];
        });

        it(@"should fail to respond to selector", ^{
            [proxy respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)] should be_falsy;
        });
    });

    it(@"raises an error when unrecognized selectors are received", ^{
        spy_on(adPlacementAdjuster);
        expect(^{
            [(id)proxy addObject:[NSObject new]]; //prints exception from objc_msgSend level.
        }).to(raise_exception);
        adPlacementAdjuster should_not have_received(@selector(isAdAtIndexPath:));
    });

    it(@"passes scrollview methods through", ^{
        [proxy scrollViewDidScroll:tableView];
        originalDelegate should have_received(@selector(scrollViewDidScroll:)).with(tableView);
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
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didSelectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:didSelectRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didDeselectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:didDeselectRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:willBeginEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:willBeginEditingRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didEndEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:didEndEditingRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didHighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didHighlightRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:didHighlightRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didUnhighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didUnhighlightRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:didUnhighlightRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });
        });

        context(@"when indexPath points to an ad index path", ^{
            it(@"prevents original delegate from receiving tableView:accessoryButtonTappedForRowWithIndexPath: ", ^{
                [proxy tableView:tableView accessoryButtonTappedForRowWithIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didSelectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didSelectRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didDeselectRowAtIndexPath: ", ^{
                [proxy tableView:tableView didDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didDeselectRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:willBeginEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:willBeginEditingRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didEndEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didEndEditingRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didHighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didHighlightRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didHighlightRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didUnhighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView didUnhighlightRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
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
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:willDisplayCell:forRowAtIndexPath:))
                .with(tableView, tableCell, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:didEndDisplayingCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndDisplayingCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:))
                .with(tableView, tableCell, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:performAction:forRowAtIndexPath:withSender: ", ^{
                [proxy tableView:tableView performAction:@selector(count) forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] withSender:@[]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:performAction:forRowAtIndexPath:withSender:))
                .with(tableView, @selector(count), [NSIndexPath indexPathForRow:1 inSection:0], @[]);
            });
        });

        context(@"when the index path points to an ad index path", ^{
            it(@"prevents original delegate from receiving -tableView:willDisplayCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView willDisplayCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:willDisplayCell:forRowAtIndexPath:));
            });

            it(@"prevents original delegate from receiving -tableView:didEndDisplayingCell:forRowAtIndexPath: ", ^{
                [proxy tableView:tableView didEndDisplayingCell:tableCell forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:));
            });


            it(@"prevents original delegate from receiving -tableView:performAction:forRowAtIndexPath:withSender: ", ^{
                [proxy tableView:tableView performAction:@selector(count) forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] withSender:@[]];
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
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

    describe(@"-tableView:canPerformAction:forRowAtIndexPath:withSender:", ^{
        beforeEach(^{
            spy_on(adPlacementAdjuster);
        });

        context(@"when the index path is not the ad cell", ^{
            it(@"offsets the index path and calls the original delegate", ^{
                [proxy tableView:tableView canPerformAction:@selector(count) forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0] withSender:@[]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:))
                .with(tableView, @selector(count), [NSIndexPath indexPathForRow:1 inSection:0], @[]);
            });
        });

        context(@"when the index path points to an ad index path", ^{
            it(@"returns own value instead of original delegate", ^{
                [proxy tableView:tableView canPerformAction:@selector(count) forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] withSender:@[]] should be_falsy;
                originalDelegate should_not have_received(@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:));
            });
        });
    });

    describe(@"one argument selectors that munge the index path and have a return value", ^{
        beforeEach(^{
            spy_on(adPlacementAdjuster);
        });

        context(@"when the index path is not the ad cell index path", ^{
            describe(@"return value is an index path", ^{
                it(@"passes through tableView:willSelectRowAtIndexPath: ", ^{
                    [proxy tableView:tableView willSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                    adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                    originalDelegate should have_received(@selector(tableView:willSelectRowAtIndexPath:))
                    .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
                });

                it(@"passes through -tableView:willDeselectRowAtIndexPath: ", ^{
                    [proxy tableView:tableView willDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                    adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                    originalDelegate should have_received(@selector(tableView:willDeselectRowAtIndexPath:))
                    .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
                });

                it(@"readjusts the return value", ^{
                    [proxy tableView:tableView willDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
                    [proxy tableView:tableView willSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
                });
            });

            it(@"passes through -tableView:shouldIndentWhileEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView shouldIndentWhileEditingRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:shouldShowMenuForRowAtIndexPath: ", ^{
                [proxy tableView:tableView shouldShowMenuForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:shouldShowMenuForRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:shouldHighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView shouldHighlightRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:shouldHighlightRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:editingStyleForRowAtIndexPath: ", ^{
                [proxy tableView:tableView editingStyleForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:editingStyleForRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:accessoryTypeForRowWithIndexPath: ", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [proxy tableView:tableView accessoryTypeForRowWithIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
#pragma clang diagnostic pop
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:accessoryTypeForRowWithIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:", ^{
                [proxy tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

            it(@"passes through -tableView:indentationLevelForRowAtIndexPath: ", ^{
                [proxy tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                adPlacementAdjuster should have_received(@selector(externalIndexPath:));
                originalDelegate should have_received(@selector(tableView:indentationLevelForRowAtIndexPath:))
                .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
            });

        });

        context(@"when indexPath points to an ad index path", ^{
            it(@"returns own value instead of original delegate for -tableView:willSelectRowAtIndexPath: ", ^{
                [proxy tableView:tableView willSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_nil;
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:willSelectRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:willDeselectRowAtIndexPath: ", ^{
                [proxy tableView:tableView willDeselectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_nil;
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:willDeselectRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:shouldIndentWhileEditingRowAtIndexPath: ", ^{
                [proxy tableView:tableView shouldIndentWhileEditingRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(NO);
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:shouldShowMenuForRowAtIndexPath: ", ^{
                [proxy tableView:tableView shouldShowMenuForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(NO);
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:shouldShowMenuForRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:shouldHighlightRowAtIndexPath: ", ^{
                [proxy tableView:tableView shouldHighlightRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(NO);
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:shouldHighlightRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:editingStyleForRowAtIndexPath: ", ^{
                [proxy tableView:tableView editingStyleForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(NO);
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:editingStyleForRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:accessoryTypeForRowWithIndexPath: ", ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                [proxy tableView:tableView accessoryTypeForRowWithIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(NO);
#pragma clang diagnostic pop
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:accessoryTypeForRowWithIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: ", ^{
                [proxy tableView:tableView titleForDeleteConfirmationButtonForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_nil;
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:));
            });

            it(@"returns own value instead of original delegate for -tableView:indentationLevelForRowAtIndexPath: ", ^{
                [proxy tableView:tableView indentationLevelForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal(0);
                adPlacementAdjuster should have_received(@selector(isAdAtIndexPath:));
                adPlacementAdjuster should_not have_received(@selector(externalIndexPath:));
                originalDelegate should_not have_received(@selector(tableView:indentationLevelForRowAtIndexPath:));
            });
        });
    });
});

SPEC_END
