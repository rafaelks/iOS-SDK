#import "STRFullAdView.h"
#import "STRAdService.h"
#import "STRDeferred.h"
#import "STRAdvertisement.h"
#import "STRInteractiveAdViewController.h"
#include "UIGestureRecognizer+Spec.h"
#import "STRBeaconService.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdViewDelegate.h"
#import "STRAdPlacement.h"
#import "STRAdRenderer.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdRendererSpec)
/*
describe(@"STRAdRenderer", ^{
    __block STRBeaconService *beaconService;
    __block STRAdvertisement *ad;
    __block STRInjector *injector;
    __block NSRunLoop<CedarDouble> *fakeRunLoop;
    __block STRAdRenderer *renderer;
    
    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];
        
        //[UIGestureRecognizer whitelistClassForGestureSnooping:[STRAdRenderer class]];
        
        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];
        
        fakeRunLoop = nice_fake_for([NSRunLoop class]);
        [injector bind:[NSRunLoop class] toInstance:fakeRunLoop];
        
        renderer = [[STRAdRenderer alloc] initWithBeaconService:beaconService runLoop:fakeRunLoop injector:injector];
        [injector bind:[STRAdRenderer class] toInstance:renderer];
        
        ad = [STRAdvertisement new];
        ad.adDescription = @"Dogs this smart deserve a home.";
        ad.title = @"Meet Porter. He's a Dog.";
        ad.advertiser = @"Brand X";
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
        ad.thirdPartyBeaconsForVisibility = @[@"//google.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForClick = @[@"//click.com?fakeParam=[timestamp]"];
        ad.thirdPartyBeaconsForPlay = @[@"//play.com?fakeParam=[timestamp]"];
    });
    
    describe(@"placing an ad in the view", ^{
        __block STRFullAdView *view;
        __block STRDeferred *deferred;
        __block UIViewController *presentingViewController;
        __block UIWindow *window;
        __block id<STRAdViewDelegate> delegate;
        __block STRAdPlacement *placement;
        
        beforeEach(^{
            view = [STRFullAdView new];
            view.frame = CGRectMake(0, 0, 100, 100);
            
            deferred = [STRDeferred defer];
            
            presentingViewController = [UIViewController new];
            window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
            window.rootViewController = presentingViewController;
            [window makeKeyAndVisible];
            
            beaconService stub_method(@selector(fireImpressionRequestForPlacementKey:));
            
            delegate = nice_fake_for(@protocol(STRAdViewDelegate));
            
            placement = [[STRAdPlacement alloc] initWithAdView:view
                                                  PlacementKey:@"placementKey"
                                      presentingViewController:presentingViewController
                                                      delegate:delegate
                                                       DFPPath:nil
                                                   DFPDeferred:nil];
        });
        
        describe(@"follows up with its delegate", ^{
            context(@"when the delegate has a success callback", ^{
                it(@"tells the delegate", ^{
                    [renderer renderAd:ad inPlacement:placement];
                    
                    delegate should have_received(@selector(adView:didFetchAdForPlacementKey:))
                    .with(view, @"placementKey");
                });
            });
            
            context(@"when the delegate does not have a success callback", ^{
                beforeEach(^{
                    delegate reject_method(@selector(adView:didFetchAdForPlacementKey:));
                });
                
                it(@"does not try to tell the delegate", ^{
                    [renderer renderAd:ad inPlacement:placement];
                    
                    delegate should_not have_received(@selector(adView:didFetchAdForPlacementKey:));
                });
            });
        });
        
        describe(@"rendering full ad", ^{
            beforeEach(^{
                spy_on(view);
                [renderer renderAd:ad inPlacement:placement];
            });
            
            it(@"fires an impression kept beacon", ^{
                beaconService should have_received(@selector(fireImpressionForAd:adSize:)).with(ad, CGSizeMake(100, 100));
            });
            
            it(@"fills out the ads' the title, description, and sponsored by", ^{
                view.adTitle.text should equal(@"Meet Porter. He's a Dog.");
                view.adDescription.text should equal(@"Dogs this smart deserve a home.");
                view.adSponsoredBy.text should equal(@"Promoted by Brand X");
            });
            
            it(@"adds the ad's image", ^{
                char imageData[100];
                [UIImagePNGRepresentation(view.adThumbnail.image) getBytes:&imageData length:100];
                
                char expectedData[100];
                [UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]) getBytes:&expectedData length:100];
                imageData should equal(expectedData);
            });
            
            it(@"relayouts view because tableviewcells need to have content in subviews to determine dimensions", ^{
                view should have_received(@selector(setNeedsLayout));
            });
            
            it(@"adds a gesture recognizer for taps", ^{
                [view.gestureRecognizers count] should equal(1);
                [view.gestureRecognizers lastObject] should be_instance_of([UITapGestureRecognizer class]);
            });
            
            describe(@"view position timer", ^{
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
                            beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//google.com?fakeParam=[timestamp]"]);
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
                    interactiveAdController.delegate should be_same_instance_as(renderer);
                });
                
                it(@"dismisses the interactive ad controller when told", ^{
                    [interactiveAdController.delegate closedInteractiveAdView:interactiveAdController];
                    
                    presentingViewController.presentedViewController should be_nil;
                });
                
                it(@"fires off a youtube play beacon", ^{
                    beaconService should have_received(@selector(fireVideoPlayEvent:adSize:)).with(ad, CGSizeMake(100, 100));
                });
                
                it(@"fires off the third party beacons for click and for play", ^{
                    beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//click.com?fakeParam=[timestamp]"]);
                    beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//play.com?fakeParam=[timestamp]"]);
                });

                describe(@"when the delegate has adView:userDidEngageAdForPlacementKey defined", ^{
                   it(@"calls the delegate", ^{
                       delegate should have_received(@selector(adView:userDidEngageAdForPlacementKey:));
                   });
                });
            });

            describe(@"when the ad is tapped on when the delegate does not have adView:userDidEngageAdForPlacementKey defined", ^{
                beforeEach(^{
                    delegate reject_method(@selector(adView:userDidEngageAdForPlacementKey:));
                    [[view.gestureRecognizers lastObject] recognize];
                });

                it(@"does not call the delegate", ^{
                    delegate should_not have_received(@selector(adView:userDidEngageAdForPlacementKey:));
                });
            });
            
            describe(@"when the view has already had an ad placed within it", ^{
                __block STRAdRenderer *secondRenderer;
                __block NSTimer *oldTimer;
                
                beforeEach(^{
                    [[fakeRunLoop.sent_messages firstObject] getArgument:&oldTimer atIndex:2];
                    
                    STRAdPlacement *placement = [[STRAdPlacement alloc] initWithAdView:view
                                                                         PlacementKey:@"placementKey"
                                                             presentingViewController:presentingViewController
                                                                             delegate:nil
                                                                              DFPPath:nil
                                                                          DFPDeferred:nil];

                    secondRenderer = [[STRAdRenderer alloc] initWithBeaconService:beaconService runLoop:fakeRunLoop injector:injector];
                    
                    [secondRenderer renderAd:ad inPlacement:placement];
                });
                
                it(@"should have cleaned up old tap gesture recognizers", ^{
                    [view.gestureRecognizers count] should equal(1);
                });
                
                it(@"invalidates the old ad's timer", ^{
                    oldTimer.isValid should be_falsy;
                    
                    __autoreleasing NSTimer *newTimer;
                    [[fakeRunLoop.sent_messages lastObject] getArgument:&newTimer atIndex:2];
                    
                    newTimer should_not be_same_instance_as(oldTimer);
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
                        interactiveAdController.delegate should be_same_instance_as(renderer);
                    });
                    
                    it(@"dismisses the interactive ad controller when told", ^{
                        [interactiveAdController.delegate closedInteractiveAdView:interactiveAdController];
                        
                        presentingViewController.presentedViewController should be_nil;
                    });
                    
                    describe(@"when the delegate has adView:willDismissModalForPlacementKey defined", ^{
                        it(@"calls the delegate", ^{
                            [interactiveAdController.delegate closedInteractiveAdView:interactiveAdController];

                            delegate should have_received(@selector(adView:willDismissModalForPlacementKey:));
                        });
                    });

                    describe(@"when the ad is tapped on when the delegate does not have adView:willDismissModalForPlacementKey defined", ^{
                        beforeEach(^{
                            delegate reject_method(@selector(adView:willDismissModalForPlacementKey:));
                        });

                        it(@"does not call the delegate", ^{
                            [interactiveAdController.delegate closedInteractiveAdView:interactiveAdController];

                            delegate should_not have_received(@selector(adView:willDismissModalForPlacementKey:));
                        });
                    });

                    it(@"fires off a clickout click beacon", ^{
                        beaconService should have_received(@selector(fireClickForAd:adSize:)).with(ad, CGSizeMake(100, 100));
                    });
                    
                    it(@"fires off the third party beacons for click", ^{
                        beaconService should have_received(@selector(fireThirdPartyBeacons:)).with(@[@"//click.com?fakeParam=[timestamp]"]);
                    });
                });
            });
            context(@"when the ad is a pinterest", ^{
                beforeEach(^{
                    ad.action = STRPinterestAd;
                    
                    view.frame = CGRectMake(0, 0, 100, 100);
                    [deferred resolveWithValue:ad];
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
                    [deferred resolveWithValue:ad];
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
                    [deferred resolveWithValue:ad];
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
            
            context(@"when the ad is a youtube video", ^{
                beforeEach(^{
                    ad.action = STRYouTubeAd;
                    
                    view.frame = CGRectMake(0, 0, 100, 100);
                    [deferred resolveWithValue:ad];
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
                    [deferred resolveWithValue:ad];
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
        
        describe(@"place an ad in a view without an ad description", ^{
            __block STRPlainAdView *view;
            __block STRDeferred *deferred;
            
            beforeEach(^{
                view = [STRPlainAdView new];
                deferred = [STRDeferred defer];
                
                placement = [[STRAdPlacement alloc] initWithAdView:view
                                                                      PlacementKey:@"placementKey"
                                                          presentingViewController:presentingViewController
                                                                          delegate:nil
                                                                           DFPPath:nil
                                                                       DFPDeferred:nil];
            });
            
            it(@"does not try to include an ad description", ^{
                expect(^{
                    [renderer renderAd:ad inPlacement:placement];
                }).to_not(raise_exception);
            });
        });
    });
});
*/
SPEC_END