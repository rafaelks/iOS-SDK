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
        ad.thirdPartyBeaconsForSilentPlay = @[@"//fake.co/3sec"];
        ad.thirdPartyBeaconsForTenSecondSilentPlay = @[@"//fake.co/10sec"];
        ad.thirdPartyBeaconsForFifteenSecondSilentPlay = @[@"//fake.co/15sec"];
        ad.thirdPartyBeaconsForThirtySecondSilentPlay = @[@"//fake.co/30sec"];
        ad.thirdPartyBeaconsForCompletedSecondSilentPlay = @[@"//fake.co/done"];
        ad.placementStatus = @"live";
    });

    it(@"adds a kvo for rate", ^{
        fakeQueuePlayer should have_received(@selector(addObserver:forKeyPath:options:context:));
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

    describe(@"-observeValueForKeyPath:", ^{
        it(@"fires a beacon if the video is paused", ^{
            fakeQueuePlayer.rate = 0.0;
            [ad observeValueForKeyPath:@"rate" ofObject:nil change:nil context:nil];
            fakeBeaconService should have_received(@selector(fireVideoViewDurationForAd:withDuration:isSilent:));
        });

        it(@"doesn't fire a beacon if the video is playing", ^{
            fakeQueuePlayer.rate = 1.0;
            [ad observeValueForKeyPath:@"rate" ofObject:nil change:nil context:nil];
            fakeBeaconService should_not have_received(@selector(fireVideoViewDurationForAd:withDuration:isSilent:));
        });
    });

    describe(@"-setupSilentPlayTimer", ^{
        it(@"sets up a boundary time observer", ^{
            [ad setupSilentPlayTimer];
            fakeQueuePlayer should have_received(@selector(addBoundaryTimeObserverForTimes:queue:usingBlock:));
        });

        describe(@"when the boundary time block is called", ^{
            beforeEach(^{
                fakeQueuePlayer stub_method(@selector(addBoundaryTimeObserverForTimes:queue:usingBlock:)).and_do(^(NSInvocation *invocation) {
                    void (^boundaryTimeBlock)() = nil;
                    [invocation getArgument:&boundaryTimeBlock atIndex:4];
                    boundaryTimeBlock();
                });
            });

            it(@"fires a silent auto play duration", ^{
                fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(2, 1));
                [ad setupSilentPlayTimer];
                fakeBeaconService should have_received(@selector(fireSilentAutoPlayDurationForAd:withDuration:));
                fakeBeaconService should_not have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:));
            });

            it(@"calls the beacon service if it's 3 seconds", ^{
                fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(3, 1));
                [ad setupSilentPlayTimer];
                fakeBeaconService should have_received(@selector(fireSilentAutoPlayDurationForAd:withDuration:));
                fakeBeaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//fake.co/3sec"], @"live");
            });

            it(@"calls the beacon service if it's 10 seconds", ^{
                fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(10, 1));
                [ad setupSilentPlayTimer];
                fakeBeaconService should have_received(@selector(fireSilentAutoPlayDurationForAd:withDuration:));
                fakeBeaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//fake.co/10sec"], @"live");
            });

            it(@"calls the beacon service if it's 15 seconds", ^{
                fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(15, 1));
                [ad setupSilentPlayTimer];
                fakeBeaconService should have_received(@selector(fireSilentAutoPlayDurationForAd:withDuration:));
                fakeBeaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//fake.co/15sec"], @"live");
            });

            it(@"calls the beacon service if it's 30 seconds", ^{
                fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(30, 1));
                [ad setupSilentPlayTimer];
                fakeBeaconService should have_received(@selector(fireSilentAutoPlayDurationForAd:withDuration:));
                fakeBeaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//fake.co/30sec"], @"live");
            });
        });
    });

    describe(@"-setupQuartileTimer", ^{
        __block AVPlayerItem *fakeAVItem;
        __block AVAsset *fakeAsset;
        beforeEach(^{
            fakeAVItem = nice_fake_for([AVPlayerItem class]);
            fakeAsset = nice_fake_for([AVAsset class]);
            fakeQueuePlayer stub_method(@selector(currentItem)).and_return(fakeAVItem);
            fakeAVItem stub_method(@selector(asset)).and_return(fakeAsset);
            fakeAsset stub_method(@selector(duration)).and_return(CMTimeMake(40, 1));
        });

        it(@"sets up a boundary time observer", ^{
            [ad setupQuartileTimer];
            fakeQueuePlayer should have_received(@selector(addBoundaryTimeObserverForTimes:queue:usingBlock:));
        });

        describe(@"when the boundary time block is called", ^{
            beforeEach(^{
                fakeQueuePlayer stub_method(@selector(addBoundaryTimeObserverForTimes:queue:usingBlock:)).and_do(^(NSInvocation *invocation) {
                    void (^boundaryTimeBlock)() = nil;
                    [invocation getArgument:&boundaryTimeBlock atIndex:4];
                    boundaryTimeBlock();
                });
            });

            it(@"fires a silent auto play duration", ^{
                fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(10, 1));
                [ad setupQuartileTimer];
                fakeBeaconService should have_received(@selector(fireVideoCompletionForAd:completionPercent:)).with(ad, [NSNumber numberWithInt:25]);
            });

            describe(@"when it's 95% complete", ^{
                it(@"fires a silent auto play duration and a third party beacon", ^{
                    fakeQueuePlayer stub_method(@selector(currentTime)).and_return(CMTimeMake(39, 1));
                    [ad setupQuartileTimer];
                    fakeBeaconService should have_received(@selector(fireVideoCompletionForAd:completionPercent:)).with(ad, [NSNumber numberWithInt:95]);
                    fakeBeaconService should have_received(@selector(fireThirdPartyBeacons:forPlacementWithStatus:)).with(@[@"//fake.co/done"], @"live");
                });
            });
        });
    });
});

SPEC_END
