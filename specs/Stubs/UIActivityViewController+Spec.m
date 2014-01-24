//
//  UIActivityViewController+Spec.m
//  SharethroughSDK
//
//  Created by sharethrough on 1/23/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <objc/runtime.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
static char const * const UIActivityViewControllerKey = "UIActivityViewControllerKey";

@implementation UIActivityViewController (Spec)

- (id)initWithActivityItems:(NSArray *)activityItems applicationActivities:(NSArray *)applicationActivities {
    self = [UIActivityViewController new];
    if (self) {
        objc_setAssociatedObject(self, UIActivityViewControllerKey, activityItems, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return self;
}

- (NSArray *)activityItems {
    return objc_getAssociatedObject(self, UIActivityViewControllerKey);
}

@end
#pragma clang diagnostic pop
