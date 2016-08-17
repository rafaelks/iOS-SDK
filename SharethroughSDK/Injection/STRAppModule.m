#import "STRAppModule.h"

#import "STRAdCache.h"
#import "STRAdGenerator.h"
#import "STRAdRenderer.h"
#import "STRAsapService.h"
#import "STRBeaconService.h"
#import "STRDateProvider.h"
#import "STRGridlikeViewAdGenerator.h"
#import "STRMediationService.h"
#import "STRNetworkClient.h"
#import "STRRestClient.h"

#import <AdSupport/AdSupport.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>

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

    [injector bind: [UIDevice class] toInstance:[UIDevice currentDevice]];

    [injector bind:[NSRunLoop class] toInstance:[NSRunLoop mainRunLoop]];

    [injector bind:[MPMoviePlayerController class] toBlock:^id(STRInjector *injector) {
        return [MPMoviePlayerController new];
    }];

    [injector bind:[AVQueuePlayer class] toBlock:^id(STRInjector *injector) {
        return [AVQueuePlayer new];
    }];

    [injector bind:[AVAudioSession class] toInstance:[AVAudioSession sharedInstance]];

    [injector bind:[STRAdCache class] toInstance:[[STRAdCache alloc] initWithDateProvider:[injector getInstance:[STRDateProvider class]]]];

    [injector bind:[STRBeaconService class] toBlock:^id(STRInjector *injector) {
        return [[STRBeaconService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                               dateProvider:[injector getInstance:[STRDateProvider class]]
                                        asIdentifierManager:[injector getInstance:[ASIdentifierManager class]]];
    }];

    [injector bind:[STRMediationService class] toInstance:[[STRMediationService alloc] initWithInjector:injector]];

    [injector bind:[STRAsapService class] toBlock:^id(STRInjector *injector) {
        return [[STRAsapService alloc] initWithRestClient:[injector getInstance:[STRRestClient class]]
                                                  adCache:[injector getInstance:[STRAdCache class]]
                                         mediationService:[injector getInstance:[STRMediationService class]]
                                      asIdentifierManager:[injector getInstance:[ASIdentifierManager class]]
                                                   device:[injector getInstance:[UIDevice class]]
                                                 injector:injector];
    }];

    [injector bind:[STRAdGenerator class] toBlock:^id(STRInjector *injector) {
        return [[STRAdGenerator alloc] initWithAsapService:[injector getInstance:[STRAsapService class]]
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
