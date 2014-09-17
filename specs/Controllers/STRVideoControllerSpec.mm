#import "STRVideoController.h"
#import "STRAdFixtures.h"
#import "STRAdVine.h"
#import "STRBeaconService.h"
#import <MediaPlayer/MediaPlayer.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRWebViewControllerSpec)

describe(@"STRVideoController", ^{
    __block STRVideoController *controller;
    __block STRAdvertisement *ad;
    __block MPMoviePlayerController *moviePlayerController;
    __block STRBeaconService *beaconService;

    beforeEach(^{
        moviePlayerController = nice_fake_for([MPMoviePlayerController class]);
        moviePlayerController stub_method(@selector(view)).and_return([UIView new]);
        beaconService = nice_fake_for([STRBeaconService class]);
    });

    describe(@"when displaying the movie", ^{
        beforeEach(^{
            ad = [STRAdFixtures ad];
            controller = [[STRVideoController alloc] initWithAd:ad moviePlayerController:moviePlayerController beaconService:beaconService];
            controller.view should_not be_nil;
        });

        it(@"displays movie player with the ad's media url", ^{
            MPMoviePlayerController *movieController = (MPMoviePlayerController *)controller.moviePlayerController;

            movieController should have_received(@selector(setContentURL:)).with(ad.mediaURL);
            controller.moviePlayerView.superview should be_same_instance_as(controller.view);
        });

        it(@"shows a spinner until the movie controls are ready", ^{
            controller.spinner.superview should be_same_instance_as(controller.view);
            [controller viewWillAppear:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerReadyForDisplayDidChangeNotification object:moviePlayerController];
            controller.spinner.superview should be_nil;
        });
    });

    context(@"when the video is a vine", ^{
        beforeEach(^{
            ad = [STRAdFixtures vineAd];
            controller = [[STRVideoController alloc] initWithAd:ad moviePlayerController:moviePlayerController beaconService:beaconService];
        });

        it(@"plays the movie with infinite repeat", ^{
            moviePlayerController should have_received(@selector(prepareToPlay));
            moviePlayerController should have_received(@selector(setRepeatMode:)).with(MPMovieRepeatModeOne);
        });
    });

    context(@"when the video is hosted", ^{
        beforeEach(^{
            ad = [STRAdFixtures ad];
            controller = [[STRVideoController alloc] initWithAd:ad moviePlayerController:moviePlayerController beaconService:beaconService];
        });

        it(@"plays the movie with infinite repeat", ^{
            moviePlayerController should have_received(@selector(prepareToPlay));
            moviePlayerController should_not have_received(@selector(setRepeatMode:));
        });
    });
});

SPEC_END
