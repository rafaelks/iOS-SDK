//
//  STRNavigationController.m
//  SharethroughSDK
//
//  Created by sharethrough on 2/11/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRNavigationController.h"

@interface STRNavigationController ()

@end

@implementation STRNavigationController

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.topViewController.preferredInterfaceOrientationForPresentation;
}

@end
