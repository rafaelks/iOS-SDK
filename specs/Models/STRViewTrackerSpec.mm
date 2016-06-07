#import "STRFullAdView.h"
#import "STRAdService.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdViewDelegate.h"
#import "STRAdPlacement.h"
#import "STRNetworkClient.h"
#import "STRAdRenderer.h"
#import "STRDateProvider.h"
#import "STRAdInstantHostedVideo.h"
#import "STRViewTracker.h"

#import <AVKit/AVKit.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRViewTrackerSpec)

describe(@"STRViewTracker", ^{
    __block STRBeaconService *beaconService;
    __block STRAdvertisement *ad;
    __block STRInjector *injector;
    __block NSRunLoop<CedarDouble> *fakeRunLoop;
    __block STRNetworkClient *fakeNetworkClient;
    __block STRDateProvider<CedarDouble> *dateProvider;
    __block STRViewTracker *viewTracker;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        fakeRunLoop = nice_fake_for([NSRunLoop class]);
        [injector bind:[NSRunLoop class] toInstance:fakeRunLoop];

        fakeNetworkClient = nice_fake_for([STRNetworkClient class]);
        [injector bind:[STRNetworkClient class] toInstance:fakeNetworkClient];

        dateProvider = nice_fake_for([STRDateProvider class]);
        [injector bind:[STRDateProvider class] toInstance:dateProvider];

        viewTracker = [[STRViewTracker alloc] initWithInjector:injector];

        ad = [STRAdvertisement new];
        ad.adDescription = @"Dogs this smart deserve a home.";
        ad.title = @"Meet Porter. He's a Dog.";
        ad.advertiser = @"Brand X";
        ad.placementStatus = @"live";
        ad.action = STRYouTubeAd;
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
        ad.thirdPartyBeaconsForImpression = @[@"//google.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForVisibility = @[@"//google.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForClick = @[@"//click.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForPlay = @[@"//play.com?fakeParam=[timestamp]"];
    });

    describe(@"tracking an ad in the view", ^{
        __block STRFullAdView *view;
        __block UIViewController *presentingViewController;
        __block UIWindow *window;
        __block id<STRAdViewDelegate> delegate;
        __block STRAdPlacement *placement;

        beforeEach(^{
            view = [STRFullAdView new];
            view.frame = CGRectMake(0, 0, 100, 100);

            presentingViewController = [UIViewController new];
            window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];

            beaconService stub_method(@selector(fireImpressionRequestForPlacement:));
            beaconService stub_method(@selector(fireThirdPartyBeacons:forPlacementWithStatus:));

            delegate = nice_fake_for(@protocol(STRAdViewDelegate));

            placement = [[STRAdPlacement alloc] initWithAdView:view
                                                  PlacementKey:@"placementKey"
                                      presentingViewController:presentingViewController
                                                      delegate:delegate
                                                       adIndex:0
                                              customProperties:nil];
        });

        describe(@"rendering full ad", ^{
            beforeEach(^{
                [viewTracker trackAd:ad inView:view withViewContorller:presentingViewController];
            });

            it(@"adds a gesture recognizer for taps", ^{
                [view.gestureRecognizers count] should equal(1);
                [view.gestureRecognizers lastObject] should be_instance_of([UITapGestureRecognizer class]);
            });

            //The below tests throw an GPFLT
            xdescribe(@"view position timer", ^{
                __block NSTimer *timer;

                beforeEach(^{
                    UIView *superView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
                    [window addSubview:superView];
                    [superView addSubview:view];

                    [[fakeRunLoop.sent_messages firstObject] getArgument:&timer atIndex:2];
                });

                subjectAction(^{
                    [timer fire];
                });

                context(@"when ad is >= 50% visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 0, 100, 100);
                    });

                    it(@"increments seconds visible", ^{
                        [timer.userInfo[@"secondsVisible"] floatValue] should be_greater_than(0.0);
                    });

                    it(@"should not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });

                    it(@"does not invalidates timer", ^{
                        timer.isValid should be_truthy;
                    });

                    context(@"and one second has passed", ^{
                        beforeEach(^{
                            timer.userInfo[@"secondsVisible"] = @1.0;
                        });

                        it(@"sends a beacon", ^{
                            beaconService should have_received(@selector(fireVisibleImpressionForAd:adSize:))
                            .with(ad, CGSizeMake(100, 100));
                        });

                        it(@"fires a third party beacon", ^{
                            beaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//google.com?fakeParam=[timestamp]"], @"live");
                        });

                        it(@"invalidates its timer", ^{
                            timer.isValid should be_falsy;
                        });
                    });

                    describe(@"when the ad goes off screen before 1 second has passed", ^{
                        beforeEach(^{
                            timer.userInfo[@"secondsVisible"] = @0.5;

                            view.frame = CGRectMake(1000, 1000, 100, 100);
                        });

                        it(@"resets the secondsVisible", ^{
                            timer.userInfo[@"secondsVisible"] should be_nil;
                        });
                    });
                });

                context(@"when the ad is 25% visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 360, 320, 480);
                    });

                    it(@"does not set secondsVisible", ^{
                        timer.userInfo[@"secondsVisible"] should be_nil;
                    });

                    it(@"should not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });

                    it(@"does not invalidates timer", ^{
                        timer.isValid should be_truthy;
                    });

                });

                context(@"when ad is 0% visible", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 481, 320, 500);
                    });

                    it(@"does not set secondsVisible", ^{
                        timer.userInfo[@"secondsVisible"] should be_nil;
                    });

                    it(@"should not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });

                    it(@"does not invalidates timer", ^{
                        timer.isValid should be_truthy;
                    });
                });

                context(@"after the ad is removed from its superview", ^{
                    beforeEach(^{
                        view.frame = CGRectMake(0, 481, 320, 500);
                        [view removeFromSuperview];
                    });

                    it(@"invalidates its timer", ^{
                        timer.isValid should be_falsy;
                    });

                    it(@"does not send a beacon", ^{
                        beaconService should_not have_received(@selector(fireVisibleImpressionForAd:adSize:));
                    });
                });
            });

            describe(@"when the ad is tapped on", ^{
                __block STRInteractiveAdViewController *interactiveAdController;

                beforeEach(^{
                    [[view.gestureRecognizers lastObject] recognize];
                    interactiveAdController = (STRInteractiveAdViewController *)presentingViewController.presentedViewController;

                });

                it(@"presents the STRInteractiveAdViewController", ^{
                    interactiveAdController should be_instance_of([STRInteractiveAdViewController class]);
                    interactiveAdController.ad should be_same_instance_as(ad);
                });

                it(@"fires off a youtube play beacon", ^{
                    beaconService should have_received(@selector(fireVideoPlayEvent:adSize:)).with(ad, CGSizeMake(100, 100));
                });

                it(@"fires off the third party beacons for click and for play", ^{
                    beaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//click.com?fakeParam=[timestamp]"], @"live");
                    beaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//play.com?fakeParam=[timestamp]"], @"live");
                });
            });

            context(@"when the ad is a clickout", ^{
                beforeEach(^{
                    ad.action = STRClickoutAd;

                    view.frame = CGRectMake(0, 0, 100, 100);
                });

                describe(@"the view is tapped on", ^{
                    __block STRInteractiveAdViewController *interactiveAdController;

                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                        interactiveAdController = (STRInteractiveAdViewController *)presentingViewController.presentedViewController;
                    });

                    it(@"presents the STRInteractiveAdViewController", ^{
                        interactiveAdController should be_instance_of([STRInteractiveAdViewController class]);
                        interactiveAdController.ad should be_same_instance_as(ad);
                    });

                    it(@"fires off a clickout click beacon", ^{
                        beaconService should have_received(@selector(fireClickForAd:adSize:)).with(ad, CGSizeMake(100, 100));
                    });

                    it(@"fires off the third party beacons for click", ^{
                        beaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//click.com?fakeParam=[timestamp]"], @"live");
                    });
                });
            });

            context(@"when the ad is an article", ^{
                beforeEach(^{
                    ad.action = STRArticleAd;

                    view.frame = CGRectMake(0, 0, 100, 100);
                });

                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                    });

                    it(@"does not fire off a clickout click beacon", ^{
                        beaconService should_not have_received(@selector(fireClickForAd:adSize:));
                    });

                    it(@"fires an article view beacon", ^{
                        beaconService should have_received(@selector(fireArticleViewForAd:)).with(ad);
                    });
                });
            });

            context(@"when the ad is a pinterest", ^{
                beforeEach(^{
                    ad.action = STRPinterestAd;

                    view.frame = CGRectMake(0, 0, 100, 100);
                });

                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                    });

                    it(@"fires off a clickout click beacon", ^{
                        beaconService should have_received(@selector(fireClickForAd:adSize:)).with(ad, CGSizeMake(100, 100));
                    });
                });
            });

            context(@"when the ad is an instagram", ^{
                beforeEach(^{
                    ad.action = STRInstagramAd;

                    view.frame = CGRectMake(0, 0, 100, 100);
                });

                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                    });

                    it(@"fires off a clickout click beacon", ^{
                        beaconService should have_received(@selector(fireClickForAd:adSize:)).with(ad, CGSizeMake(100, 100));
                    });
                });
            });

            context(@"when the ad is a hosted video", ^{
                beforeEach(^{
                    ad.action = STRHostedVideoAd;

                    view.frame = CGRectMake(0, 0, 100, 100);
                });

                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                    });

                    it(@"fires off a video play beacon", ^{
                        beaconService should have_received(@selector(fireVideoPlayEvent:adSize:)).with(ad, CGSizeMake(100, 100));
                    });


                });
            });

            context(@"when the ad is an instant hosted video", ^{
                __block UIViewController *interactiveAdController;

                beforeEach(^{
                    ad = [STRAdInstantHostedVideo new];
                    ad.action = STRHostedVideoAd;

                    [viewTracker trackAd:ad inView:view withViewContorller:presentingViewController];

                    view.frame = CGRectMake(0, 0, 100, 100);
                });

                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                        interactiveAdController = presentingViewController.presentedViewController;
                    });

                    it(@"fires off a video play beacon", ^{
                        beaconService should have_received(@selector(fireVideoPlayEvent:adSize:));
                    });

                    it(@"presents the STRInteractiveAdViewController", ^{
                        interactiveAdController should be_instance_of([AVPlayerViewController class]);
                    });
                });
            });

            context(@"when the ad is a youtube video", ^{
                beforeEach(^{
                    ad.action = STRYouTubeAd;

                    view.frame = CGRectMake(0, 0, 100, 100);
                });
                
                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                    });
                    
                    it(@"fires off a video play beacon", ^{
                        beaconService should have_received(@selector(fireVideoPlayEvent:adSize:)).with(ad, CGSizeMake(100, 100));
                    });
                });
            });
            
            context(@"when the ad is a vine", ^{
                beforeEach(^{
                    ad.action = STRVineAd;
                    
                    view.frame = CGRectMake(0, 0, 100, 100);
                });
                
                describe(@"the view is tapped on", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)beaconService reset_sent_messages];
                        [[view.gestureRecognizers lastObject] recognize];
                    });
                    
                    it(@"fires off a video play beacon", ^{
                        beaconService should have_received(@selector(fireVideoPlayEvent:adSize:)).with(ad, CGSizeMake(100, 100));
                    });
                });
            });
        });
    });
});

SPEC_END