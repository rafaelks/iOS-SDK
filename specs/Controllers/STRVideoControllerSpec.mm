#import "STRVideoController.h"
#import "STRAdFixtures.h"
#import "STRAdVine.h"
#import <MediaPlayer/MediaPlayer.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRWebViewControllerSpec)

describe(@"STRVideoController", ^{
    __block STRVideoController *controller;
    __block STRAdVine *ad;
    __block MPMoviePlayerController *moviePlayerController;

    beforeEach(^{
        ad = [STRAdFixtures vineAd];
        moviePlayerController = nice_fake_for([MPMoviePlayerController class]);
        moviePlayerController stub_method(@selector(view)).and_return([UIView new]);
        controller = [[STRVideoController alloc] initWithAd:ad moviePlayerController:moviePlayerController];
    });

    it(@"displays a web view with the ad's media url", ^{
        MPMoviePlayerController *movieController = (MPMoviePlayerController *)controller.moviePlayerController;

        movieController should have_received(@selector(setContentURL:)).with(ad.mediaURL);
        controller.view should be_same_instance_as(movieController.view);
    });

    it(@"plays the movie with infinite repeat", ^{
        moviePlayerController should have_received(@selector(prepareToPlay));
        moviePlayerController should have_received(@selector(setRepeatMode:)).with(MPMovieRepeatModeOne);
    });
});

SPEC_END
