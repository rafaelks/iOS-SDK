#import "STRInteractiveAdViewController.h"
#import "UIActivityViewController+Spec.h"
#include "UIBarButtonItem+Spec.h"
#include "UIImage+Spec.h"
#import "STRBeaconService.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdYouTube.h"
#import "STRYouTubeViewController.h"
#import "STRVideoController.h"
#import "STRAdVine.h"
#import "STRAdHostedVideo.h"
#import "STRAdPinterest.h"
#import "STRAdFixtures.h"
#import <MediaPlayer/MediaPlayer.h>
#import "STRClickoutViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInteractiveAdViewControllerSpec)

describe(@"STRInteractiveAdViewController", ^{
    __block STRInteractiveAdViewController *controller;
    __block STRAdvertisement *ad;
    __block UIDevice *device;
    __block UIApplication *application;
    __block STRBeaconService *beaconService;
    __block STRInjector *injector;

    void(^setUpController)(void) = ^{
        controller = [[STRInteractiveAdViewController alloc] initWithAd:ad
                                                                 device:device
                                                            application:application
                                                          beaconService:beaconService
                                                               injector:injector];
        UIWindow *window = [UIWindow new];
        [window addSubview:controller.view];
        [controller.view layoutIfNeeded];
    };

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];
        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        device = [UIDevice currentDevice];
        application = [UIApplication sharedApplication];
    });

    describe(@"when the ad does not have a custom button", ^{
        it(@"inserts the ad title and promoted by information", ^{
            ad = [STRAdFixtures vineAd];
            setUpController();

            controller.adInfoHeader.text should equal(@"Meet A 15-year-old Cancer Researcher Promoted by Intel");
        });
    });

    describe(@"when the ad has a custom button", ^{
        it(@"inserts the custom button", ^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();

            controller.customButton.title should equal(@"Hear More");
        });
    });

    describe(@"when the ad is a youtube ad", ^{
        __block STRYouTubeViewController *youTubeViewController;

        beforeEach(^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();
            youTubeViewController = [controller.childViewControllers firstObject];
        });

        it(@"presents a youtube view controller", ^{
            youTubeViewController should be_instance_of([STRYouTubeViewController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(youTubeViewController.view);
        });

        it(@"gives that youtube view controller the ad", ^{
            youTubeViewController.ad should be_same_instance_as(ad);
        });
    });

    describe(@"when the ad's media url is playable within the MoviePlayer", ^{
        void(^itPlaysTheAdInAVideoController)(void) = ^{
            __block STRVideoController *videoController;
            __block MPMoviePlayerController *moviePlayerController;

            beforeEach(^{
                moviePlayerController = nice_fake_for([MPMoviePlayerController class]);
                moviePlayerController stub_method(@selector(view)).and_return([UIView new]);
                [injector bind:[MPMoviePlayerController class] toInstance:moviePlayerController];
                setUpController();

                videoController = [controller.childViewControllers firstObject];
            });

            it(@"presents a generic video controller", ^{
                videoController should be_instance_of([STRVideoController class]);
                controller.contentView.subviews.firstObject should be_same_instance_as(videoController.view);
            });

            it(@"gives that video controller the ad", ^{
                videoController.ad should be_same_instance_as(ad);
            });
        };

        describe(@"when the ad is a vine ad", ^{
            beforeEach(^{
                ad = [STRAdFixtures vineAd];
            });

            itPlaysTheAdInAVideoController();
        });
        
        describe(@"when the ad is a hosted video", ^{
            beforeEach(^{
                ad = [STRAdFixtures hostedVideoAd];
            });

            itPlaysTheAdInAVideoController();
        });
    });

    describe(@"when the ad is a clickout", ^{
        __block STRClickoutViewController *clickoutViewController;

        beforeEach(^{
            ad = (id)[STRAdFixtures clickoutAd];
            setUpController();
            clickoutViewController = [controller.childViewControllers firstObject];
        });

        it(@"presents a clickout view controller", ^{
            clickoutViewController should be_instance_of([STRClickoutViewController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(clickoutViewController.view);
        });

        it(@"gives that clickout view controller the ad", ^{
            clickoutViewController.ad should be_same_instance_as(ad);
        });
    });

    describe(@"when the ad is pinterest image", ^{
        __block STRClickoutViewController *clickoutViewController;
        
        beforeEach(^{
            ad = (id)[STRAdFixtures pinterestAd];
            setUpController();
            clickoutViewController = [controller.childViewControllers firstObject];
        });
        
        it(@"presents a clickout view controller", ^{
            clickoutViewController should be_instance_of([STRClickoutViewController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(clickoutViewController.view);
        });
        
        it(@"gives that clickout view controller the ad", ^{
            clickoutViewController.ad should be_same_instance_as(ad);
        });
    });
    
    describe(@"when the ad is instagram image", ^{
        __block STRClickoutViewController *clickoutViewController;

        beforeEach(^{
            ad = (id)[STRAdFixtures pinterestAd];
            ad.action = STRInstagramAd;
            setUpController();
            clickoutViewController = [controller.childViewControllers firstObject];
        });

        it(@"presents a clickout view controller", ^{
            clickoutViewController should be_instance_of([STRClickoutViewController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(clickoutViewController.view);
        });

        it(@"gives that clickout view controller the ad", ^{
            clickoutViewController.ad should be_same_instance_as(ad);
        });
    });

    describe(@"when the ad is unknown", ^{
        __block STRClickoutViewController *clickoutViewController;

        beforeEach(^{
            ad = (id)[STRAdFixtures pinterestAd];
            ad.action = @"Unknown";
            setUpController();
            clickoutViewController = [controller.childViewControllers firstObject];
        });

        it(@"presents a clickout view controller", ^{
            clickoutViewController should be_instance_of([STRClickoutViewController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(clickoutViewController.view);
        });

        it(@"gives that clickout view controller the ad", ^{
            clickoutViewController.ad should be_same_instance_as(ad);
        });
    });

    describe(@"when the user taps the done button", ^{
        __block id<STRInteractiveAdViewControllerDelegate> delegate;

        beforeEach(^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();
            spy_on(controller.childViewController);
            delegate = nice_fake_for(@protocol(STRInteractiveAdViewControllerDelegate));
            controller.delegate = delegate;
            [controller.doneButton tap];
        });

        it(@"notifies its delegate", ^{
            delegate should have_received(@selector(closedInteractiveAdView:)).with(controller);
        });

        it(@"tells the child to cleanup", ^{
            controller.childViewController should have_received(@selector(cleanupResources));
        });
    });

    describe(@"when the ad is the privacy information", ^{
        __block STRClickoutViewController *clickoutViewController;

        beforeEach(^{
            ad = (id)[STRAdFixtures privacyInformationAd];
            setUpController();
            clickoutViewController = [controller.childViewControllers firstObject];
        });

        it(@"presents a clickout view controller", ^{
            clickoutViewController should be_instance_of([STRClickoutViewController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(clickoutViewController.view);
        });

        it(@"gives that clickout view controller the ad", ^{
            clickoutViewController.ad should be_same_instance_as(ad);
        });

        it(@"sets the title without a promoted by slug", ^{
            controller.adInfoHeader.text should equal(@"Privacy Information");
        });
    });

    xdescribe(@"when the user taps the share button on an iPhone", ^{
        __block UIActivityViewController *activityController;
        beforeEach(^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();

            spy_on(device);
            device stub_method(@selector(userInterfaceIdiom)).and_return(UIUserInterfaceIdiomPhone);
            [controller.shareButton tap];
            activityController = (UIActivityViewController *) controller.presentedViewController;
        });

        it(@"presents the UIActivityViewController", ^{
            activityController should be_instance_of([UIActivityViewController class]);
            activityController.activityItems should equal(@[ad.title, @"http://bit.ly/23kljr"]);
        });

        describe(@"when the user selects a share option", ^{
            beforeEach(^{
                activityController.completionHandler(UIActivityTypeMail, YES);
            });

            it(@"fires a sharing beacon", ^{
                beaconService should have_received(@selector(fireShareForAd:shareType:)).with(ad, UIActivityTypeMail);
            });
        });

        describe(@"when the user does not select a share option", ^{
            beforeEach(^{
                activityController.completionHandler(nil, NO);
            });

            it(@"does not fire a share beacon", ^{
                beaconService should_not have_received(@selector(fireShareForAd:shareType:));
            });
        });
    });

    xdescribe(@"when the user taps the share button on an iPad", ^{
        beforeEach(^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();
            spy_on(device);
            device stub_method(@selector(userInterfaceIdiom)).and_return(UIUserInterfaceIdiomPad);
            [controller.shareButton tap];
        });

        it(@"shows the UIActivityViewController in a popover", ^{
            UIActivityViewController *activityController = (UIActivityViewController *) controller.sharePopoverController.contentViewController;
            activityController should be_instance_of([UIActivityViewController class]);
            activityController.activityItems should equal(@[ad.title, @"http://bit.ly/23kljr"]);

            controller.sharePopoverController.isPopoverVisible should be_truthy;
        });

        it(@"closes the popover when user taps done", ^{
            [controller.doneButton tap];
            controller.sharePopoverController.isPopoverVisible should be_falsy;
        });

        it(@"keeps the same popover if the user taps the share button again", ^{
            UIPopoverController *existingPopoverController = controller.sharePopoverController;
            [controller.sharePopoverController dismissPopoverAnimated:NO];
            [controller.shareButton tap];
            controller.sharePopoverController should be_same_instance_as(existingPopoverController);
            controller.sharePopoverController.isPopoverVisible should be_truthy;
        });
    });

    describe(@"when the user taps on the custom button", ^{
        beforeEach(^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();
            spy_on(application);
            application stub_method(@selector(openURL:));
            [controller.customButton tap];
        });

        it(@"calls open url", ^{
            application should have_received(@selector(openURL:));
        });
    });
});

SPEC_END
