//
//  STRTableViewDelegateProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTableViewDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"

static NSArray *strPassthroughSelectors;
static NSArray *strOneArgumentSelectors;
static NSArray *strTwoArgumentSelectors;
static NSArray *strSelectorsWithReturnValues;
static NSArray *strOneArgumentWithReturnIndexPathSelectors;


@interface STRTableViewDelegateProxy ()

@property (weak, nonatomic) id<UITableViewDelegate> originalDelegate;
@property (strong, nonatomic) STRAdPlacementAdjuster *adPlacementAdjuster;
@property (assign, nonatomic) CGFloat adHeight;

@end

@implementation STRTableViewDelegateProxy

- (id)initWithOriginalDelegate:(id<UITableViewDelegate>)originalDelegate adPlacementAdjuster:(STRAdPlacementAdjuster *)adPlacementAdjuster adHeight:(CGFloat)adHeight {
    if (self) {
        self.originalDelegate = originalDelegate;
        self.adPlacementAdjuster = adPlacementAdjuster;
        self.adHeight = adHeight;

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
    if (indexPathIndex == -1) return;

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

    if ([strOneArgumentWithReturnIndexPathSelectors containsObject:NSStringFromSelector(invocation.selector)]) {
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
    if ([strOneArgumentSelectors containsObject:NSStringFromSelector(invocation.selector)]
        || [strSelectorsWithReturnValues containsObject:NSStringFromSelector(invocation.selector)]
        || [strOneArgumentWithReturnIndexPathSelectors containsObject:NSStringFromSelector(invocation.selector)]) {
        return 3;
    } else if ([strTwoArgumentSelectors containsObject:NSStringFromSelector(invocation.selector)]) {
        return 4;
    }

    return -1;
}

- (BOOL)willAdjustIndexPathForSelector:(SEL)selector {
    NSString *string = NSStringFromSelector(selector);

    if ([strOneArgumentSelectors containsObject:string] ||
        [strTwoArgumentSelectors containsObject:string] ||
        [strSelectorsWithReturnValues containsObject:string] ||
        [strOneArgumentWithReturnIndexPathSelectors containsObject:string]) {
        return YES;
    }
    return NO;
}


#pragma mark - Selector heck

- (void)instantiateSelectors {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        strPassthroughSelectors = @[
                                    NSStringFromSelector(@selector(tableView:viewForHeaderInSection:)),
                                    NSStringFromSelector(@selector(tableView:viewForFooterInSection:)),
                                    NSStringFromSelector(@selector(tableView:heightForHeaderInSection:)),
                                    NSStringFromSelector(@selector(tableView:estimatedHeightForHeaderInSection:)),
                                    NSStringFromSelector(@selector(tableView:heightForFooterInSection:)),
                                    NSStringFromSelector(@selector(tableView:estimatedHeightForFooterInSection:)),
                                    NSStringFromSelector(@selector(tableView:willDisplayHeaderView:forSection:)),
                                    NSStringFromSelector(@selector(tableView:willDisplayFooterView:forSection:)),
                                    NSStringFromSelector(@selector(tableView:didEndDisplayingHeaderView:forSection:)),
                                    NSStringFromSelector(@selector(tableView:didEndDisplayingFooterView:forSection:)),
                                    ];

        strOneArgumentSelectors = @[
                                    NSStringFromSelector(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:didSelectRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:didDeselectRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:willBeginEditingRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:didEndEditingRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:didHighlightRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:didUnhighlightRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:estimatedHeightForRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:heightForRowAtIndexPath:)),
                                    ];

        strTwoArgumentSelectors = @[
                                    NSStringFromSelector(@selector(tableView:willDisplayCell:forRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)),
                                    NSStringFromSelector(@selector(tableView:performAction:forRowAtIndexPath:withSender:)),
                                    NSStringFromSelector(@selector(tableView:canPerformAction:forRowAtIndexPath:withSender:)),
                                    ];

        strSelectorsWithReturnValues = @[
                                              NSStringFromSelector(@selector(tableView:shouldIndentWhileEditingRowAtIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:shouldShowMenuForRowAtIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:shouldHighlightRowAtIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:editingStyleForRowAtIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:accessoryTypeForRowWithIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:titleForDeleteConfirmationButtonForRowAtIndexPath:)),
                                              NSStringFromSelector(@selector(tableView:indentationLevelForRowAtIndexPath:))
                                              ];

        strOneArgumentWithReturnIndexPathSelectors = @[
                                                       NSStringFromSelector(@selector(tableView:willSelectRowAtIndexPath:)),
                                                       NSStringFromSelector(@selector(tableView:willDeselectRowAtIndexPath:)),
                                                       ];
    });
}

@end
