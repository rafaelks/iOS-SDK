//
//  STRDFPAppModule.m
//  SharethroughSDK
//
//  Created by Engineer @editor.local on 9/4/14.
//  Copyright (c) 2014 Sharethrough. All rights reserved.
//

#import "STRDFPAppModule.h"

#import "STRAdService.h"
#import "STRDFPAdGenerator.h"
#import "STRRestClient.h"

#import "GADBannerView.h"

@implementation STRDFPAppModule

- (void)configureWithInjector:(STRInjector *)injector {
    [super configureWithInjector:injector];

    [injector bind:[GADBannerView class] toInstance:[[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait]];

    [injector bind:[STRDFPAdGenerator class]
        toInstance:[[STRDFPAdGenerator alloc] initWithAdService:[injector getInstance:[STRAdService class]]
                                                       injector:injector
                                                     restClient:[injector getInstance:[STRRestClient class]]
                                                     bannerView:[injector getInstance:[GADBannerView class]]]];
}

@end
