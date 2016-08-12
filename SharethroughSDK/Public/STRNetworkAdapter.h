//
//  STRNetworkAdapter.h
//  SharethroughSDK
//
//  Created by Peter Kinmond on 8/11/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STRNetworkAdapterDelegate.h"

@interface STRNetworkAdapter : NSObject

- (void)loadAdWithParameters:(NSDictionary *)parameters;

@property (nonatomic, weak) id<STRNetworkAdapterDelegate> delegate;

@end
