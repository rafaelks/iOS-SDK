#import "STRAdvertisement.h"
#import "STRAdInstantHostedVideo.h"
#import "STRImages.h"
#import "STRAppModule.h"
#import "STRBeaconService.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdInstantHostedVideoSpec)

describe(@"STRADInstantHostedVideo", ^{
    __block STRAdInstantHostedVideo *ad;
    __block STRInjector *injector;
    __block STRBeaconService *fakeBeaconService;
    __block AVQueuePlayer *fakeQueuePlayer;
    __block AVURLAsset *fakeAsset;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        fakeQueuePlayer = [AVQueuePlayer new];
        spy_on(fakeQueuePlayer);
        [injector bind:[AVQueuePlayer class] toInstance:fakeQueuePlayer];

        fakeAsset = nice_fake_for([AVURLAsset class]);
        [injector bind:[AVURLAsset class] toInstance:fakeAsset];

        fakeBeaconService = nice_fake_for([STRBeaconService class]);
        [injector bind:[STRBeaconService class] toInstance:fakeBeaconService];

        ad = [[STRAdInstantHostedVideo alloc] initWithInjector:injector];
        ad.thumbnailImage = [UIImage imageNamed:@"fixture_image.png"];
    });

    xdescribe(@"-dealloc", ^{
        it(@"removes time observers", ^{
            //ARC doesn't allow a direct call to dealloc
            //[ad dealloc];
            fakeQueuePlayer should have_received(@selector(removeTimeObserver:));
        });
    });

    describe(@"setMediaURL", ^{
        __block NSURL *mediaURL;
        beforeEach(^{
            mediaURL = [NSURL URLWithString:@"file:fake/video.mp4"];
            ad.mediaURL = mediaURL;
        });

        it(@"inits the asset with the media URL", ^{
            ad.mediaURL should equal(mediaURL);
        });
    });

    describe(@"setThumbnailImageInView", ^{
        __block UIImageView *imageView;

        beforeEach(^{
            imageView = [UIImageView new];
        });

        it(@"adds the ad's image", ^{
            [ad setThumbnailImageInView:imageView];

            char imageData[100];
            [UIImagePNGRepresentation(imageView.image) getBytes:&imageData length:100];

            char expectedData[100];
            [UIImagePNGRepresentation([UIImage imageNamed:@"fixture_image.png"]) getBytes:&expectedData length:100];
            imageData should equal(expectedData);
        });

        describe(@"before engagement", ^{
            beforeEach(^{
                [ad setThumbnailImageInView:imageView];
            });

            it(@"adds a subview", ^{
                imageView.subviews.count should equal(1);
            });

            it(@"sets the player to muted", ^{
                fakeQueuePlayer.muted should be_truthy;
            });

            it(@"plays the player", ^{
                fakeQueuePlayer should have_received(@selector(play));
            });
        });

        describe(@"after engagement", ^{
            beforeEach(^{
                [ad viewControllerForPresentingOnTap];
                [ad setThumbnailImageInView:imageView];
            });

            it(@"does not add a subview", ^{
                imageView.subviews.count should equal(0);
            });

            it(@"does not play the player", ^{
                fakeQueuePlayer should_not have_received(@selector(play));
            });
        });
    });

    describe(@"viewControllerForPresentingOnTapWithInjector", ^{
        __block UIViewController *viewControllerForPresenting;

        beforeEach(^{
            viewControllerForPresenting = [ad viewControllerForPresentingOnTap];
        });

        it(@"removes the silent time observer", ^{
            fakeQueuePlayer should have_received(@selector(removeTimeObserver:));
        });

        it(@"fire an auto play engagemnt ad beacon", ^{
            fakeBeaconService should have_received(@selector(fireAutoPlayVideoEngagementForAd:withDuration:));
        });

        it(@"returns an AVPlayerViewController", ^{
            viewControllerForPresenting should be_instance_of([AVPlayerViewController class]);
        });

        it(@"unmutes the player", ^{
            fakeQueuePlayer.muted should be_falsy;
        });
    });

    describe(@"adVisibleInView", ^{
        it(@"plays the player", ^{
            [ad adVisibleInView:nil];
            fakeQueuePlayer should have_received(@selector(play));
        });
    });

    describe(@"adNotVisibleInView", ^{
        it(@"pauses the player", ^{
            [ad adNotVisibleInView:nil];
            fakeQueuePlayer should have_received(@selector(pause));
        });
    });
});

SPEC_END
