//
//  STRViewTracker.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 6/4/15.
//  Copyright (c) 2015 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STRInjector, STRAdvertisement;

@interface STRViewTracker : NSObject

- (id)initWithInjector:(STRInjector *)injector;
- (void)trackAd:(STRAdvertisement *)strAd inView:(UIView *)view withViewContorller:(UIViewController *)viewController;
- (void)addDiclosureTapRecognizerToView:(UIView *)view;
+ (void)unregisterView:(UIView *)view;

@end
