//
//  STRCollectionViewDelegateProxy.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/6/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRCollectionViewDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"

static NSArray *strSelectorsWithReturnValues;
static NSArray *strPassthroughSelectors;
static NSArray *strSelectorsWithIndexPathAtThree;
static NSArray *strSelectorsWithIndexPathAtFour;

@interface STRCollectionViewDelegateProxy  ()
@property (nonatomic, strong) STRAdPlacementAdjuster *adjuster;
@end

@implementation STRCollectionViewDelegateProxy
- (id)initWithOriginalDelegate:(id<UICollectionViewDelegate>)delegate
                    adAdjuster:(STRAdPlacementAdjuster *)adjuster {
    self = [super init];
    if (self) {
        self.originalDelegate = delegate;
        self.adjuster = adjuster;
        [self instantiateSelectors];
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [[self class] instancesRespondToSelector:aSelector] || [self.originalDelegate respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.originalDelegate respondsToSelector:aSelector] && [strPassthroughSelectors containsObject:NSStringFromSelector(aSelector)]) {
        return self.originalDelegate;
    }

    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSInteger index = [self indexOfIndexPathArgumentInInvocation:anInvocation];

    __autoreleasing NSIndexPath *indexPath;
    [anInvocation getArgument:&indexPath atIndex:index];

    if ([self.adjuster isAdAtIndexPath:indexPath]) {
        if ([strSelectorsWithReturnValues containsObject:NSStringFromSelector(anInvocation.selector)]) {
            id returnValue = 0;
            [anInvocation setReturnValue:&returnValue];
        }
        return;
    }

    __autoreleasing NSIndexPath *externalIndexPath = [self.adjuster externalIndexPath:indexPath];
    [anInvocation setArgument:&externalIndexPath atIndex:index];
    [anInvocation invokeWithTarget:self.originalDelegate];
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

#pragma mark - Private

- (NSInteger)indexOfIndexPathArgumentInInvocation:(NSInvocation *)invocation {
    NSInteger index = 3;
    if ([strSelectorsWithIndexPathAtThree containsObject:NSStringFromSelector(invocation.selector)]) {
        index = 4;
    } else if ([strSelectorsWithIndexPathAtFour containsObject:NSStringFromSelector(invocation.selector)]) {
        index = 5;
    }
    return index;
}

#pragma mark - Selector Groups

- (void)instantiateSelectors {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        strSelectorsWithIndexPathAtThree = @[NSStringFromSelector(@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)),
                                    NSStringFromSelector(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)),
                                    NSStringFromSelector(@selector(collectionView:performAction:forItemAtIndexPath:withSender:))];

        strSelectorsWithIndexPathAtFour = @[NSStringFromSelector(@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:))];

        strSelectorsWithReturnValues = @[
                                              NSStringFromSelector(@selector(collectionView:shouldSelectItemAtIndexPath:)),
                                              NSStringFromSelector(@selector(collectionView:shouldDeselectItemAtIndexPath:)),
                                              NSStringFromSelector(@selector(collectionView:shouldHighlightItemAtIndexPath:)),
                                              NSStringFromSelector(@selector(collectionView:shouldShowMenuForItemAtIndexPath:)),
                                              NSStringFromSelector(@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)),
                                              ];

        strPassthroughSelectors = @[NSStringFromSelector(@selector(collectionView:transitionLayoutForOldLayout:newLayout:))];
    });
}
@end
