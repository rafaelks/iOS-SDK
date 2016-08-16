//
//  STRNetworkAdapter.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRNetworkAdapterDelegate.h"

@class STRAdPlacement, STRInjector;

@interface STRNetworkAdapter : NSObject

- (void)loadAdWithParameters:(NSDictionary *)parameters;

@property (nonatomic, weak) id<STRNetworkAdapterDelegate> delegate;

// Only needed for Sharethrough network adapter
@property (nonatomic, strong) STRAdPlacement *placement;
@property (nonatomic, strong) STRInjector *injector;

@end
