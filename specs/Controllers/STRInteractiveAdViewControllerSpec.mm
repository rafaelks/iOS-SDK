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
#import "STRAdFixtures.h"
#import <MediaPlayer/MediaPlayer.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInteractiveAdViewControllerSpec)

describe(@"STRInteractiveAdViewController", ^{
    __block STRInteractiveAdViewController *controller;
    __block STRAdvertisement *ad;
    __block UIDevice *device;
    __block STRBeaconService *beaconService;
    __block STRInjector *injector;

    void(^setUpController)(void) = ^{
        controller = [[STRInteractiveAdViewController alloc] initWithAd:ad device:device beaconService:beaconService injector:injector];
        UIWindow *window = [UIWindow new];
        [window addSubview:controller.view];
        [controller.view layoutIfNeeded];
    };


    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];
        beaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:beaconService];

        device = [UIDevice currentDevice];
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

    describe(@"when the ad is a vine ad", ^{
        __block STRVideoController *videoController;
        __block MPMoviePlayerController *moviePlayerController;

        beforeEach(^{
            ad = [STRAdFixtures vineAd];
            moviePlayerController = nice_fake_for([MPMoviePlayerController class]);
            moviePlayerController stub_method(@selector(view)).and_return([UIView new]);
            [injector bind:[MPMoviePlayerController class] toInstance:moviePlayerController];
            setUpController();

            videoController = [controller.childViewControllers firstObject];
        });

        it(@"presents a generic web view controller", ^{
            videoController should be_instance_of([STRVideoController class]);
            controller.contentView.subviews.firstObject should be_same_instance_as(videoController.view);
        });

        it(@"gives that web view controller the ad", ^{
            videoController.ad should be_same_instance_as(ad);
        });
    });

    describe(@"when the user taps the done button", ^{
        __block id<STRInteractiveAdViewControllerDelegate> delegate;

        beforeEach(^{
            ad = [STRAdFixtures youTubeAd];
            setUpController();
            delegate = nice_fake_for(@protocol(STRInteractiveAdViewControllerDelegate));
            controller.delegate = delegate;
            [controller.doneButton tap];
        });

        it(@"notifies its delegate", ^{
            delegate should have_received(@selector(closedInteractiveAdView:)).with(controller);
        });
    });

    describe(@"when the user taps the share button on an iPhone", ^{
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

    describe(@"when the user taps the share button on an iPad", ^{
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
});

SPEC_END
