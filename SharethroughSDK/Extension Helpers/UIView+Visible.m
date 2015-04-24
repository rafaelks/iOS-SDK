//
//  UIView+Visible.m
//  SharethroughSDK
//
//  Created by Mark Meyer on 4/24/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import "UIView+Visible.h"

@implementation UIView (Visible)

- (CGFloat)percentVisible {
    CGRect viewFrame = [self convertRect:self.bounds toView:nil];

    CGRect intersection = CGRectIntersection(viewFrame, self.window.frame);

    CGFloat intersectionArea = intersection.size.width * intersection.size.height;
    CGFloat viewArea = self.frame.size.width * self.frame.size.height;
    CGFloat percentVisible = intersectionArea/viewArea;
    return percentVisible;
}

@end
