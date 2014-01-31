//
//  STRTableViewDelegateProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/30/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRTableViewDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"

static NSArray *passthroughSelectors;
static NSArray *oneArgumentSelectors;
static NSArray *twoArgumentSelectors;

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

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDelegate respondsToSelector:aSelector] && [passthroughSelectors containsObject:NSStringFromSelector(aSelector)]) {
        return self.originalDelegate;
    }

    return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if ([invocation selector] == @selector(tableView:heightForRowAtIndexPath:)) {
        __autoreleasing NSIndexPath *indexPath;
        [invocation getArgument:&indexPath atIndex:3];

        CGFloat height = self.adHeight;
        if ([self.adPlacementAdjuster isAdAtIndexPath:indexPath]) {
            [invocation setReturnValue:&height];
        } else {
            __autoreleasing NSIndexPath *newIndexPath = [self.adPlacementAdjuster adjustedIndexPath:indexPath];
            [invocation setArgument:&newIndexPath atIndex:3];
            [invocation invokeWithTarget:self.originalDelegate];
        }

        return;
    }

    NSInteger indexPathIndex = -1;

    if ([oneArgumentSelectors containsObject:NSStringFromSelector(invocation.selector)]) {
        indexPathIndex = 3;
    } else if ([twoArgumentSelectors containsObject:NSStringFromSelector(invocation.selector)]) {
        indexPathIndex = 4;
    } else {
        return;
    }

    __autoreleasing NSIndexPath *indexPath;
    [invocation getArgument:&indexPath atIndex:indexPathIndex];

    if ([self.adPlacementAdjuster isAdAtIndexPath:indexPath]) {
        return;
    }

    __autoreleasing NSIndexPath *newIndexPath = [self.adPlacementAdjuster adjustedIndexPath:indexPath];
    [invocation setArgument:&newIndexPath atIndex:indexPathIndex];
    [invocation invokeWithTarget:self.originalDelegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    if ([self.originalDelegate isKindOfClass:[NSObject class]]) {
        return [(NSObject *)self.originalDelegate methodSignatureForSelector:sel];
    }
    
    if ([self.originalDelegate isKindOfClass:[NSProxy class]]) {
        return [(NSProxy *)self.originalDelegate methodSignatureForSelector:sel];
    }

    return nil;
}

#pragma mark - Selector heck

- (void)instantiateSelectors {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        passthroughSelectors = @[
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

        oneArgumentSelectors = @[
                                 NSStringFromSelector(@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:didSelectRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:didDeselectRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:willBeginEditingRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:didEndEditingRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:didHighlightRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:didUnhighlightRowAtIndexPath:)),
                                 ];

        twoArgumentSelectors = @[
                                 NSStringFromSelector(@selector(tableView:willDisplayCell:forRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)),
                                 NSStringFromSelector(@selector(tableView:performAction:forRowAtIndexPath:withSender:))
                                 ];
    });
}


@end
