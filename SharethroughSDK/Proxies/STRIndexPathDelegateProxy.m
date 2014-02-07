//
//  STRIndexPathDelegateProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRIndexPathDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"

static NSArray *strSelectorsWithVoidReturnType;
static NSArray *strSelectorsWithReturnValues;
static NSArray *strSelectorsWhichReturnIndexPaths;


@interface STRIndexPathDelegateProxy ()

@property (weak, nonatomic) id originalDelegate;
@property (strong, nonatomic) STRAdPlacementAdjuster *adPlacementAdjuster;
@property (assign, nonatomic) CGFloat adHeight;

@end

@implementation STRIndexPathDelegateProxy

- (id)initWithOriginalDelegate:(id<UITableViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster adHeight:(CGFloat)adHeight {
    if (self) {
        self.originalDelegate = originalDelegate;
        self.adPlacementAdjuster = adPlacementAdjuster;
        self.adHeight = adHeight;

        [self instantiateSelectors];
    }

    return self;
}

- (id)initWithOriginalDelegate:(id<UICollectionViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster {
    self = [super init];
    if (self) {
        self.originalDelegate = originalDelegate;
        self.adPlacementAdjuster = adPlacementAdjuster;

        [self instantiateSelectors];
    }

    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [[self class] instancesRespondToSelector:aSelector] || [self.originalDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDelegate respondsToSelector:aSelector] && ![self willAdjustIndexPathForSelector:aSelector]){
        return self.originalDelegate;
    }

    return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([invocation selector] == @selector(tableView:heightForRowAtIndexPath:)
        || [invocation selector] == @selector(tableView:estimatedHeightForRowAtIndexPath:)) {
        [self handleHeightsInvocation:invocation];
        return;
    }

    NSInteger indexPathIndex = [self indexOfIndexPathArgumentInInvocation:invocation];
    __autoreleasing NSIndexPath *indexPath;
    [invocation getArgument:&indexPath atIndex:indexPathIndex];

    if ([self.adPlacementAdjuster isAdAtIndexPath:indexPath]) {
        if ([strSelectorsWithReturnValues containsObject:NSStringFromSelector(invocation.selector)]) {
            id returnValue = 0;
            [invocation setReturnValue:&returnValue];
        }
        return;
    }

    __autoreleasing NSIndexPath *externalIndexPath = [self.adPlacementAdjuster externalIndexPath:indexPath];
    [invocation setArgument:&externalIndexPath atIndex:indexPathIndex];
    [invocation invokeWithTarget:self.originalDelegate];

    if ([strSelectorsWhichReturnIndexPaths containsObject:NSStringFromSelector(invocation.selector)]) {
        __autoreleasing NSIndexPath *indexPath;
        [invocation getReturnValue:&indexPath];
        if (indexPath) {
            NSIndexPath *trueIndexPath = [self.adPlacementAdjuster trueIndexPath:indexPath];
            [invocation setReturnValue:&trueIndexPath];
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if ([self.originalDelegate isKindOfClass:[NSObject class]]) {
        return [(NSObject *)self.originalDelegate methodSignatureForSelector:sel];
    }
    
    if ([self.originalDelegate isKindOfClass:[NSProxy class]]) {
        return [(NSProxy *)self.originalDelegate methodSignatureForSelector:sel];
    }

    return [super methodSignatureForSelector:sel];
}

#pragma mark - Special cases

- (void)handleHeightsInvocation:(NSInvocation *)invocation {
    __autoreleasing NSIndexPath *indexPath;
    [invocation getArgument:&indexPath atIndex:3];

    CGFloat height = self.adHeight;
    if ([self.adPlacementAdjuster isAdAtIndexPath:indexPath]) {
        [invocation setReturnValue:&height];
    } else {
        __autoreleasing NSIndexPath *newIndexPath = [self.adPlacementAdjuster externalIndexPath:indexPath];
        [invocation setArgument:&newIndexPath atIndex:3];
        [invocation invokeWithTarget:self.originalDelegate];
    }
}

#pragma mark - Private

- (NSInteger)indexOfIndexPathArgumentInInvocation:(NSInvocation *)invocation {
    NSString *selectorString = NSStringFromSelector(invocation.selector);
    return [[selectorString componentsSeparatedByString:@":"] indexOfObjectPassingTest:^BOOL(NSString *substring, NSUInteger idx, BOOL *stop) {
        return ( [substring rangeOfString:@"IndexPath"].location != NSNotFound );
    }] + 2;
}

- (BOOL)willAdjustIndexPathForSelector:(SEL)selector {
    NSString *selectorString = NSStringFromSelector(selector);

    return ([strSelectorsWithVoidReturnType containsObject:selectorString] ||
            [strSelectorsWithReturnValues containsObject:selectorString] ||
            [strSelectorsWhichReturnIndexPaths containsObject:selectorString]);
}


#pragma mark - Selector heck

- (void)instantiateSelectors {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        strSelectorsWithVoidReturnType = @[
                                           NSStringFromSelector(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:didSelectRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:didDeselectRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:willBeginEditingRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:didEndEditingRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:didHighlightRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:didUnhighlightRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:estimatedHeightForRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:heightForRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:willDisplayCell:forRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)),
                                           NSStringFromSelector(@selector(tableView:performAction:forRowAtIndexPath:withSender:)),
                                           NSStringFromSelector(@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:)),

                                           NSStringFromSelector(@selector(collectionView:didSelectItemAtIndexPath:)),
                                           NSStringFromSelector(@selector(collectionView:didDeselectItemAtIndexPath:)),
                                           NSStringFromSelector(@selector(collectionView:didHighlightItemAtIndexPath:)),
                                           NSStringFromSelector(@selector(collectionView:didUnhighlightItemAtIndexPath:)),
                                           NSStringFromSelector(@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)),
                                           NSStringFromSelector(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)),
                                           NSStringFromSelector(@selector(collectionView:performAction:forItemAtIndexPath:withSender:)),
                                           NSStringFromSelector(@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:))];

        strSelectorsWithReturnValues = @[
                                         NSStringFromSelector(@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)),
                                         NSStringFromSelector(@selector(tableView:shouldShowMenuForRowAtIndexPath:)),
                                         NSStringFromSelector(@selector(tableView:shouldHighlightRowAtIndexPath:)),
                                         NSStringFromSelector(@selector(tableView:editingStyleForRowAtIndexPath:)),
                                         NSStringFromSelector(@selector(tableView:accessoryTypeForRowWithIndexPath:)),
                                         NSStringFromSelector(@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)),
                                         NSStringFromSelector(@selector(tableView:indentationLevelForRowAtIndexPath:)),

                                         NSStringFromSelector(@selector(collectionView:shouldSelectItemAtIndexPath:)),
                                         NSStringFromSelector(@selector(collectionView:shouldDeselectItemAtIndexPath:)),
                                         NSStringFromSelector(@selector(collectionView:shouldHighlightItemAtIndexPath:)),
                                         NSStringFromSelector(@selector(collectionView:shouldShowMenuForItemAtIndexPath:)),
                                         NSStringFromSelector(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)),
                                         ];

        strSelectorsWhichReturnIndexPaths = @[
                                              NSStringFromSelector(@selector(tableView:willSelectRowAtIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:willDeselectRowAtIndexPath:)),
                                              ];
    });
}

@end
