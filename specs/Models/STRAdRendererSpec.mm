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
#import "STRNetworkClient.h"
#import "STRAdRenderer.h"
#import "STRDateProvider.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdRendererSpec)

describe(@"STRAdRenderer", ^{
    __block STRBeaconService *beaconService;
    __block STRAdvertisement *ad;
    __block STRInjector *injector;
    __block NSRunLoop<CedarDouble> *fakeRunLoop;
    __block STRNetworkClient *fakeNetworkClient;
    __block STRAdRenderer *renderer;
    __block STRDateProvider<CedarDouble> *dateProvider;
    
    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        fakeRunLoop = nice_fake_for([NSRunLoop class]);
        [injector bind:[NSRunLoop class] toInstance:fakeRunLoop];

        fakeNetworkClient = nice_fake_for([STRNetworkClient class]);
        [injector bind:[STRNetworkClient class] toInstance:fakeNetworkClient];
        
        dateProvider = nice_fake_for([STRDateProvider class]);

        renderer = [[STRAdRenderer alloc] initWithBeaconService:beaconService dateProvider:dateProvider runLoop:fakeRunLoop networkClient:fakeNetworkClient injector:injector];
        [injector bind:[STRAdRenderer class] toInstance:renderer];

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
            beaconService stub_method(@selector(fireThirdPartyBeacons:forPlacementWithStatus:));
            
            delegate = nice_fake_for(@protocol(STRAdViewDelegate));
            
            placement = [[STRAdPlacement alloc] initWithAdView:view
                                                  PlacementKey:@"placementKey"
                                      presentingViewController:presentingViewController
                                                      delegate:delegate
                                                       adIndex:0
                                                  isDirectSold:NO
                                              customProperties:nil];
        });
        
        describe(@"follows up with its delegate", ^{
            context(@"when the delegate has a success callback", ^{
                it(@"tells the delegate", ^{
                    [renderer renderAd:ad inPlacement:placement];

                    delegate should have_received(@selector(adView:didFetchAd:ForPlacementKey:atIndex:))
                    .with(view, ad, @"placementKey", 0);
                });
            });

            context(@"when the delegate does not have a success callback", ^{
                beforeEach(^{
                    delegate reject_method(@selector(adView:didFetchAd:ForPlacementKey:atIndex:));
                });

                it(@"does not try to tell the delegate", ^{
                    [renderer renderAd:ad inPlacement:placement];

                    delegate should_not have_received(@selector(adView:didFetchAd:ForPlacementKey:atIndex:));
                });
            });
        });
        
        describe(@"rendering full ad", ^{
            beforeEach(^{
                beaconService stub_method("fireImpressionForAd:adSize:").and_return(YES);
                [renderer renderAd:ad inPlacement:placement];
            });
            
            it(@"fires an impression kept beacon", ^{
                beaconService should have_received(@selector(fireImpressionForAd:adSize:)).with(ad, CGSizeMake(100, 100));
            });

            it(@"fires third party impression beacons", ^{
                beaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(ad.thirdPartyBeaconsForImpression, ad.placementStatus);
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
            
            it(@"adds the platform log", ^{
                [view.adThumbnail.subviews count] should equal(1);
            });

            xit(@"relayouts view because tableviewcells need to have content in subviews to determine dimensions", ^{
                spy_on(view);
                [renderer renderAd:ad inPlacement:placement];
                view should have_received(@selector(setNeedsLayout));   
            });
            
            it(@"adds a gesture recognizer for taps", ^{
                [view.gestureRecognizers count] should equal(1);
                [view.gestureRecognizers lastObject] should be_instance_of([UITapGestureRecognizer class]);
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
        });

        describe(@"when the impression beacon has already been fired", ^{
            beforeEach(^{
                beaconService stub_method("fireImpressionForAd:adSize:").and_return(NO);
                [renderer renderAd:ad inPlacement:placement];
            });

            it(@"fires an impression kept beacon", ^{
                beaconService should have_received(@selector(fireImpressionForAd:adSize:)).with(ad, CGSizeMake(100, 100));
            });

            it(@"fires third party impression beacons", ^{
                beaconService should_not have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:));
            });
        });

        describe(@"place an ad in a view without an ad description", ^{
            __block STRPlainAdView *view;
            __block STRDeferred *deferred;
            
            beforeEach(^{
                view = [STRPlainAdView new];
                deferred = [STRDeferred defer];
                
                placement = [[STRAdPlacement alloc] init];
                placement.adView = view;
                placement.placementKey = @"placementKey";
                placement.presentingViewController = presentingViewController;
            });
            
            it(@"does not try to include an ad description", ^{
                expect(^{
                    [renderer renderAd:ad inPlacement:placement];
                }).to_not(raise_exception);
            });
        });
    });
});

SPEC_END