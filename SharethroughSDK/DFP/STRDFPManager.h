//
//  STRDFPManager.h
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 8/27/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STRAdView.h"
#import "STRAdViewDelegate.h"
#import "STRAdPlacement.h"
#import "STRInjector.h"
#import "STRPromise.h"

@interface STRDFPManager : NSObject

@property (nonatomic, strong) STRInjector *injector;

+ (instancetype)sharedInstance;

- (void)cacheAdPlacement:(STRAdPlacement *)adPlacement;

- (STRPromise *)renderCreative:(NSString *)creativeKey inPlacement:(NSString *)DFPPath;

- (void)updateDelegateWithNoAdShownforPlacement:(NSString *)DFPPath;
@end
