#import "STRAdvertisement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdvertisementSpec)

describe(@"STRAdvertisement", ^{
    __block STRAdvertisement *ad;

    beforeEach(^{
        ad = [STRAdvertisement new];
        ad.advertiser = @"ginny minis";
        ad.mediaUrl = [NSURL URLWithString:@"http://www.youtube.com/watch?v=BWAK0J8Uhzk"];
    });

    it(@"has a sponsored by method that prefixes the 'Promoted by' string", ^{
        [ad sponsoredBy] should equal(@"Promoted by ginny minis");
    });

    it(@"can return the youtube video id based on the media url", ^{
        [ad youtubeVideoId] should equal(@"BWAK0J8Uhzk");
    });
});

SPEC_END
