//
//  STRMediationAdapter.h
//  SharethroughSDK
//
//  Created by Mark Meyer on 7/26/16.
//  Copyright © 2016 Sharethrough. All rights reserved.
//

#import "STRMediationDelegate.h"

@interface STRMediationAdapter : NSObject

@property (nonatomic, weak) id<STRMediationDelegate> delegate;

- (void)fetchAdWithCustomParameters:(NSDictionary *)parameters;

@end
