#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRAdService.h"
#import "STRBeaconService.h"
#import "STRRestClient.h"
#import "STRNetworkClient.h"
#import "STRDateProvider.h"
#import <AdSupport/AdSupport.h>

@interface STRAppModule ()

@property (nonatomic, assign) BOOL staging;

@end

@implementation STRAppModule

+ (instancetype)moduleWithStaging:(BOOL)staging {
    STRAppModule *module = [self new];
    module.staging = staging;
    return module;
}

- (void)configureWithInjector:(STRInjector *)injector {
    [injector bind:[STRNetworkClient class] toInstance:[STRNetworkClient new]];

    [injector bind:[STRRestClient class] toBlockAsSingleton:^id(STRInjector *injector) {
        return [[STRRestClient alloc] initWithStaging:self.staging
                                        networkClient:[injector getInstance:[STRNetworkClient class]]];
    }];

    [injector bind:[STRDateProvider class] toBlock:^id(STRInjector *injector) {
        return [STRDateProvider new];
    }];

    [injector bind:[ASIdentifierManager class] toInstance:[ASIdentifierManager sharedManager]];

    [injector bind:[STRBeaconService class] toBlock:^id(STRInjector *injector) {
        return [[STRBeaconService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                               dateProvider:[injector getInstance:[STRDateProvider class]]
                                        asIdentifierManager:[injector getInstance:[ASIdentifierManager class]]];
    }];

    [injector bind:[STRAdService class] toBlock:^id(STRInjector *injector) {
        return [[STRAdService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                          networkClient:[injector getInstance:[STRNetworkClient class]]];
    }];

    [injector bind:[STRAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRAdGenerator alloc] initWithAdService:[injector getInstance:[STRAdService class]]
                                           beaconService:[injector getInstance:[STRBeaconService class]]];
    }];
}

@end
