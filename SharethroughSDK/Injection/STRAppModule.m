#import "STRAppModule.h"

#import "STRAdCache.h"
#import "STRAdGenerator.h"
#import "STRAdRenderer.h"
#import "STRAdService.h"
#import "STRBeaconService.h"
#import "STRDateProvider.h"
#import "STRGridlikeViewAdGenerator.h"
#import "STRNetworkClient.h"
#import "STRRestClient.h"

#import <AdSupport/AdSupport.h>
#import <MediaPlayer/MediaPlayer.h>

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

    [injector bind:[MPMoviePlayerController class] toBlock:^id(STRInjector *injector) {
        return [MPMoviePlayerController new];
    }];

    [injector bind:[STRAdCache class] toInstance:[[STRAdCache alloc] initWithDateProvider:[injector getInstance:[STRDateProvider class]]]];

    [injector bind:[STRBeaconService class] toBlock:^id(STRInjector *injector) {
        return [[STRBeaconService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                               dateProvider:[injector getInstance:[STRDateProvider class]]
                                        asIdentifierManager:[injector getInstance:[ASIdentifierManager class]]];
    }];

    [injector bind:[STRAdService class] toBlock:^id(STRInjector *injector) {
        return [[STRAdService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                          networkClient:[injector getInstance:[STRNetworkClient class]]
                                                adCache:[injector getInstance:[STRAdCache class]]
                                          beaconService:[injector getInstance:[STRBeaconService class]]
                                    asIdentifierManager:[injector getInstance:[ASIdentifierManager class]]];
    }];

    [injector bind:[STRAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRAdGenerator alloc] initWithAdService:[injector getInstance:[STRAdService class]]
                                                injector:injector];
    }];

    [injector bind:[STRGridlikeViewAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRGridlikeViewAdGenerator alloc] initWithInjector:injector];
    }];

    [injector bind:[STRAdRenderer class] toBlock:^id(STRInjector *injector) {
        return [[STRAdRenderer alloc] initWithBeaconService:[injector getInstance:[STRBeaconService class]]
                                               dateProvider:[injector getInstance:[STRDateProvider class]]
                                                    runLoop:[injector getInstance:[NSRunLoop class]]
                                              networkClient:[injector getInstance:[STRNetworkClient class]]
                                                   injector:injector];
    }];
}

@end
