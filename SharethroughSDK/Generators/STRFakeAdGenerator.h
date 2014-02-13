//
//  STRFakeAdGenerator.h
//  SharethroughSDK
//
//  Created by sharethrough on 2/5/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRAdGenerator.h"
#import "SharethroughSDK.h"

@class STRInjector;

@interface STRFakeAdGenerator : STRAdGenerator

- (id)initWithAdType:(STRFakeAdType)adType withInjector:(STRInjector *)injector;

@end
