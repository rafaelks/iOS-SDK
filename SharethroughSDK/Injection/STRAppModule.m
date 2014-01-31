#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRAdService.h"
#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDateProvider.h"
#import <AdSupport/AdSupport.h>
#import "STRTableViewAdGenerator.h"
#import "STRAdCache.h"


@implementation STRAppModule

- (void)configureWithInjector:(STRInjector *)injector {
    [injector bind:[STRNetworkClient class] toInstance:[STRNetworkClient new]];

    [injector bind:[STRRestClient class] toBlockAsSingleton:^id(STRInjector *injector) {
        return [[STRRestClient alloc] initWithNetworkClient:[injector getInstance:[STRNetworkClient class]]];
    }];

    [injector bind:[STRDateProvider class] toBlock:^id(STRInjector *injector) {
        return [STRDateProvider new];
    }];

    [injector bind:[ASIdentifierManager class] toInstance:[ASIdentifierManager sharedManager]];

    [injector bind:[NSRunLoop class] toInstance:[NSRunLoop mainRunLoop]];

    [injector bind:[STRBeaconService class] toBlock:^id(STRInjector *injector) {
        return [[STRBeaconService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                               dateProvider:[injector getInstance:[STRDateProvider class]]
                                        asIdentifierManager:[injector getInstance:[ASIdentifierManager class]]];
    }];

    [injector bind:[STRAdService class] toBlock:^id(STRInjector *injector) {
        return [[STRAdService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                          networkClient:[injector getInstance:[STRNetworkClient class]] adCache:[injector getInstance:[STRAdCache class]]];
    }];

    [injector bind:[STRAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRAdGenerator alloc] initWithAdService:[injector getInstance:[STRAdService class]]
                                           beaconService:[injector getInstance:[STRBeaconService class]]
                                                 runLoop:[injector getInstance:[NSRunLoop class]]];
    }];

    [injector bind:[STRTableViewAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRTableViewAdGenerator alloc] initWithInjector:injector];
    }];

    [injector bind:[STRAdCache class] toInstance:[[STRAdCache alloc] initWithDateProvider:[injector getInstance:[STRDateProvider class]]]];
}

@end
