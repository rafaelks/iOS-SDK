#import "STRAdPlacementAdjuster.h"
#import "STRFullCollectionViewDelegate.h"
#import "STRCollectionViewDelegate.h"
#import "STRIndexPathDelegateProxy.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRCollectionViewDelegateProxySpec)

describe(@"STRIndexPathDelegateProxy UICollectionViewDelegate", ^{
    __block STRIndexPathDelegateProxy *proxy;
    __block STRFullCollectionViewDelegate *originalDelegate;
    __block UICollectionView *collectionView;
    __block STRAdPlacementAdjuster *adjuster;
    __block NSIndexPath *adIndexPath;
    __block NSIndexPath *trueIndexPath;
    __block NSIndexPath *externalIndexPath;
    
    beforeEach(^{
        originalDelegate = [STRFullCollectionViewDelegate new];
        spy_on(originalDelegate);
        collectionView = nice_fake_for([UICollectionView class]);
        collectionView stub_method(@selector(numberOfItemsInSection:)).with(0).and_return(2);
        
        adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        spy_on(adjuster);
        
        proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adjuster adSize:CGSizeZero];
    });
    
    describe(@"when an ad is loaded", ^{
        beforeEach(^{
            adjuster.adLoaded = YES;
            adIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
            trueIndexPath = [NSIndexPath indexPathForItem:2 inSection:0];
            externalIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        });
        
        context(@"when using a complete delegate", ^{
            it(@"responds to selector", ^{
                [proxy respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)] should be_truthy;
            });
        });
        
        context(@"when using an empty/incomplete delegate", ^{
            __block STRCollectionViewDelegate *emptyDelegate;
            beforeEach(^{
                emptyDelegate = [STRCollectionViewDelegate new];
                spy_on(emptyDelegate);
                proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:emptyDelegate adPlacementAdjuster:adjuster adSize:CGSizeZero];
            });
            
            it(@"should not respond to selector", ^{
                [proxy respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)] should be_falsy;
            });
        });
        
        describe(@"1 argument selectors w/ return values", ^{
            __block BOOL returnValue;
            afterEach(^{
                adjuster should have_received(@selector(isAdAtIndexPath:));
                
            });
            
            describe(@"when the index path is an ad cell", ^{
                afterEach(^{
                    returnValue should equal(NO);
                });
                
                describe(@"-collectionView:shouldSelectItemAtIndexPath:", ^{
                    beforeEach(^{
                        returnValue = [proxy collectionView:collectionView shouldSelectItemAtIndexPath:adIndexPath];
                    });
                    
                    it(@"returns NO and does not pass through", ^{
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:shouldSelectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:shouldDeselectItemAtIndexPath:", ^{
                    beforeEach(^{
                        returnValue = [proxy collectionView:collectionView shouldDeselectItemAtIndexPath:adIndexPath];
                    });
                    
                    it(@"does not pass through", ^{
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:shouldDeselectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:shouldHighlightItemAtIndexPath:", ^{
                    beforeEach(^{
                        returnValue = [proxy collectionView:collectionView shouldHighlightItemAtIndexPath:adIndexPath];
                    });
                    
                    it(@"does not pass through", ^{
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:shouldHighlightItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:shouldShowMenuForItemAtIndexPath:", ^{
                    beforeEach(^{
                        returnValue = [proxy collectionView:collectionView shouldHighlightItemAtIndexPath:adIndexPath];
                    });
                    it(@"does not pass through", ^{
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:shouldShowMenuForItemAtIndexPath:));
                    });
                });
            });
            
            describe(@"when the index path is NOT an ad cell", ^{
                describe(@"-collectionView:shouldSelectItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldSelectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldSelectItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
                
                describe(@"-collectionView:shouldDeselectItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldDeselectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldDeselectItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
                
                describe(@"-collectionView:shouldHighlightItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldHighlightItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldHighlightItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
                
                describe(@"-collectionView:shouldShowMenuForItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldShowMenuForItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldShowMenuForItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
            });
        });
        
        describe(@"1 argument selectors w/ no return value", ^{
            afterEach(^{
                adjuster should have_received(@selector(isAdAtIndexPath:));
            });
            
            describe(@"when the index path is an ad cell", ^{
                describe(@"-collectionView:didSelectItemAtIndexPath:", ^{
                    it(@"does not pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didSelectItemAtIndexPath:adIndexPath];
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:didSelectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:didDeselectItemAtIndexPath:", ^{
                    it(@"does not pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didDeselectItemAtIndexPath:adIndexPath];
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:didDeselectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:didHighlightItemAtIndexPath:", ^{
                    it(@"does not pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didHighlightItemAtIndexPath:adIndexPath];
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:didHighlightItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:didUnhiglightItemAtIndexPath:", ^{
                    it(@"does not pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didUnhighlightItemAtIndexPath:adIndexPath];
                        adjuster should_not have_received(@selector(externalIndexPath:));
                        originalDelegate should_not have_received(@selector(collectionView:didUnhighlightItemAtIndexPath:));
                    });
                });
            });
            
            
            describe(@"when the index path is NOT an ad cell", ^{
                describe(@"-collectionView:didSelectItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didSelectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should have_received(@selector(collectionView:didSelectItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
                
                describe(@"-collectionView:didDeselectItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didDeselectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should have_received(@selector(collectionView:didDeselectItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
                
                describe(@"-collectionView:didHighlightItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didHighlightItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should have_received(@selector(collectionView:didHighlightItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
                
                describe(@"-collectionView:didUnhiglightItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didUnhighlightItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should have_received(@selector(collectionView:didUnhighlightItemAtIndexPath:)).with(collectionView, externalIndexPath);
                    });
                });
            });
            
        });
        
        describe(@"–collectionView:didEndDisplayingCell:forItemAtIndexPath:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:externalIndexPath];
                    [proxy collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:trueIndexPath];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                    originalDelegate should have_received(@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)).with(collectionView, Arguments::anything, externalIndexPath);
                });
            });
            
            context(@"when the cell is an ad cell", ^{
                it(@"does not call through to the original", ^{
                    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:adIndexPath];
                    [proxy collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:adIndexPath];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should_not have_received(@selector(externalIndexPath:));
                    originalDelegate should_not have_received(@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:));
                });
            });
        });
        
        describe(@"–collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    UICollectionReusableView *reusableView = nice_fake_for([UICollectionReusableView class]);
                    [proxy collectionView:collectionView didEndDisplayingSupplementaryView:reusableView forElementOfKind:@"fakeViewKind" atIndexPath:trueIndexPath];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                    originalDelegate should have_received(@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)).with(collectionView, reusableView, @"fakeViewKind", externalIndexPath);
                });
            });
            
            context(@"when the cell is an ad cell", ^{
                it(@"does not call through to the original", ^{
                    UICollectionReusableView *reusableView = nice_fake_for([UICollectionReusableView class]);
                    [proxy collectionView:collectionView didEndDisplayingSupplementaryView:reusableView forElementOfKind:@"fakeViewKind" atIndexPath:adIndexPath];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should_not have_received(@selector(externalIndexPath:));
                    originalDelegate should_not have_received(@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:));
                });
            });
        });
        
        describe(@"–collectionView:canPerformAction:forItemAtIndexPath:withSender:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    [proxy collectionView:collectionView
                         canPerformAction:@selector(willPresentAlertView:)
                       forItemAtIndexPath:trueIndexPath
                               withSender:collectionView];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                    originalDelegate should have_received(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)).with(collectionView, @selector(willPresentAlertView:), externalIndexPath, collectionView);
                });
            });
            
            context(@"when the cell is an ad cell", ^{
                it(@"does not call through to the original", ^{
                    [proxy collectionView:collectionView
                         canPerformAction:@selector(willPresentAlertView:)
                       forItemAtIndexPath:adIndexPath
                               withSender:collectionView];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should_not have_received(@selector(externalIndexPath:));
                    originalDelegate should_not have_received(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:));
                });
            });
        });
        
        describe(@"–collectionView:performAction:forItemAtIndexPath:withSender:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    [proxy collectionView:collectionView
                            performAction:@selector(willPresentAlertView:)
                       forItemAtIndexPath:trueIndexPath
                               withSender:collectionView];
                    
                    originalDelegate should have_received(@selector(collectionView:performAction:forItemAtIndexPath:withSender:)).with(collectionView, @selector(willPresentAlertView:), externalIndexPath, collectionView);
                });
            });
            
            context(@"when the cell is an ad cell", ^{
                it(@"does not call through to the original", ^{
                    [proxy collectionView:collectionView
                            performAction:@selector(willPresentAlertView:)
                       forItemAtIndexPath:adIndexPath
                               withSender:collectionView];
                    
                    originalDelegate should_not have_received(@selector(collectionView:performAction:forItemAtIndexPath:withSender:));
                });
            });
            
        });
        
        describe(@"-collectionView:transitionLayoutForOldLayout:newLayout:", ^{
            it(@"passes through to the original delegate", ^{
                UICollectionViewLayout *oldLayout = [UICollectionViewLayout new];
                UICollectionViewLayout *newLayout = [UICollectionViewLayout new];
                
                [proxy collectionView:collectionView transitionLayoutForOldLayout:oldLayout newLayout:newLayout];
                
                originalDelegate should have_received(@selector(collectionView:transitionLayoutForOldLayout:newLayout:)).with(collectionView, oldLayout, newLayout);
            });
        });
        
        describe(@"-collectionView:layout:sizeForItemAtIndexPath", ^{
            context(@"when the index path is not the ad cell", ^{
                __block UICollectionViewLayout *layout;
                
                beforeEach(^{
                    layout = nice_fake_for([UICollectionViewLayout class]);
                });
                
                it(@"offsets the index path and calls through to the original delegate", ^{
                    [proxy collectionView:collectionView layout:layout sizeForItemAtIndexPath:trueIndexPath];
                    
                    originalDelegate should have_received(@selector(collectionView:layout:sizeForItemAtIndexPath:)).with(collectionView, layout, externalIndexPath);
                });
            });
            
            context(@"when the index path for the ad cell", ^{
                __block UICollectionViewLayout *layout;
                
                beforeEach(^{
                    layout = nice_fake_for([UICollectionViewLayout class]);
                    proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adjuster adSize:CGSizeMake(100.0, 200.0)];
                });
                
                it(@"returns the passed in ad size", ^{
                    CGSize size = [proxy collectionView:collectionView layout:layout sizeForItemAtIndexPath:adIndexPath];
                    
                    originalDelegate should_not have_received(@selector(collectionView:layout:sizeForItemAtIndexPath:));
                    size should equal(CGSizeMake(100.0, 200.0));
                });
            });
        });
    });
    
    describe(@"when an ad is not loaded", ^{
        beforeEach(^{
            adIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
            trueIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
            externalIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        });
        
        context(@"when using a complete delegate", ^{
            it(@"responds to selector", ^{
                [proxy respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)] should be_truthy;
            });
        });
        
        context(@"when using an empty/incomplete delegate", ^{
            __block STRCollectionViewDelegate *emptyDelegate;
            beforeEach(^{
                emptyDelegate = [STRCollectionViewDelegate new];
                spy_on(emptyDelegate);
                proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:emptyDelegate adPlacementAdjuster:adjuster adSize:CGSizeZero];
            });
            
            it(@"should not respond to selector", ^{
                [proxy respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)] should be_falsy;
            });
        });
        
        describe(@"1 argument selectors w/ return values", ^{
            afterEach(^{
                adjuster should have_received(@selector(isAdAtIndexPath:));
                
            });
            
            describe(@"when the index path is NOT an ad cell", ^{
                describe(@"-collectionView:shouldSelectItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldSelectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldSelectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:shouldDeselectItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldDeselectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldDeselectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:shouldHighlightItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldHighlightItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldHighlightItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:shouldShowMenuForItemAtIndexPath:", ^{
                    it(@"adjusts the index path before passing through", ^{
                        [proxy collectionView:collectionView shouldShowMenuForItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:));
                        originalDelegate should have_received(@selector(collectionView:shouldShowMenuForItemAtIndexPath:));
                    });
                });
            });
        });

        describe(@"1 argument selectors w/ no return value", ^{
            afterEach(^{
                adjuster should have_received(@selector(isAdAtIndexPath:));
            });
            
            describe(@"when the index path is NOT an ad cell", ^{
                describe(@"-collectionView:didSelectItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didSelectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should have_received(@selector(collectionView:didSelectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:didDeselectItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didDeselectItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should_not have_received(@selector(collectionView:didSelectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:didHighlightItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didHighlightItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should_not have_received(@selector(collectionView:didSelectItemAtIndexPath:));
                    });
                });
                
                describe(@"-collectionView:didUnhiglightItemAtIndexPath:", ^{
                    it(@"does pass through to the original delegate.", ^{
                        [proxy collectionView:collectionView didUnhighlightItemAtIndexPath:trueIndexPath];
                        adjuster should have_received(@selector(externalIndexPath:)).with(trueIndexPath);
                        originalDelegate should_not have_received(@selector(collectionView:didSelectItemAtIndexPath:));
                    });
                });
            });
            
        });
        
        describe(@"–collectionView:didEndDisplayingCell:forItemAtIndexPath:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:externalIndexPath];
                    [proxy collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:trueIndexPath];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should have_received(@selector(externalIndexPath:));
                    originalDelegate should have_received(@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:));
                });
            });
        });
        
        describe(@"–collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    UICollectionReusableView *reusableView = nice_fake_for([UICollectionReusableView class]);
                    [proxy collectionView:collectionView didEndDisplayingSupplementaryView:reusableView forElementOfKind:@"fakeViewKind" atIndexPath:trueIndexPath];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should have_received(@selector(externalIndexPath:));
                    originalDelegate should have_received(@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:));
                });
            });
        });
        
        describe(@"–collectionView:canPerformAction:forItemAtIndexPath:withSender:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    [proxy collectionView:collectionView
                         canPerformAction:@selector(willPresentAlertView:)
                       forItemAtIndexPath:trueIndexPath
                               withSender:collectionView];
                    
                    adjuster should have_received(@selector(isAdAtIndexPath:));
                    adjuster should have_received(@selector(externalIndexPath:));
                    originalDelegate should have_received(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:));
                });
            });
        });
        
        describe(@"–collectionView:performAction:forItemAtIndexPath:withSender:", ^{
            context(@"when the cell is not an ad cell", ^{
                it(@"adjusts the index path and calls through to original", ^{
                    [proxy collectionView:collectionView
                            performAction:@selector(willPresentAlertView:)
                       forItemAtIndexPath:trueIndexPath
                               withSender:collectionView];
                    
                    originalDelegate should have_received(@selector(collectionView:performAction:forItemAtIndexPath:withSender:));
                });
            });
        });
        
        describe(@"-collectionView:transitionLayoutForOldLayout:newLayout:", ^{
            it(@"passes through to the original delegate", ^{
                UICollectionViewLayout *oldLayout = [UICollectionViewLayout new];
                UICollectionViewLayout *newLayout = [UICollectionViewLayout new];
                
                [proxy collectionView:collectionView transitionLayoutForOldLayout:oldLayout newLayout:newLayout];
                
                originalDelegate should have_received(@selector(collectionView:transitionLayoutForOldLayout:newLayout:)).with(collectionView, oldLayout, newLayout);
            });
        });
        
        describe(@"-collectionView:layout:sizeForItemAtIndexPath", ^{
            context(@"when the index path is not the ad cell", ^{
                __block UICollectionViewLayout *layout;
                
                beforeEach(^{
                    layout = nice_fake_for([UICollectionViewLayout class]);
                });
                
                it(@"offsets the index path and calls through to the original delegate", ^{
                    [proxy collectionView:collectionView layout:layout sizeForItemAtIndexPath:trueIndexPath];
                    
                    originalDelegate should have_received(@selector(collectionView:layout:sizeForItemAtIndexPath:));
                });
            });
            
            context(@"when the index path for the ad cell", ^{
                __block UICollectionViewLayout *layout;
                
                beforeEach(^{
                    layout = nice_fake_for([UICollectionViewLayout class]);
                    proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:originalDelegate adPlacementAdjuster:adjuster adSize:CGSizeMake(100.0, 200.0)];
                });
                
                it(@"returns the original cell size", ^{
                    CGSize size = [proxy collectionView:collectionView layout:layout sizeForItemAtIndexPath:adIndexPath];
                    
                    originalDelegate should have_received(@selector(collectionView:layout:sizeForItemAtIndexPath:));
                    size should equal(CGSizeMake(0.0, 0.0));
                });
            });
        });
    });
});

SPEC_END
