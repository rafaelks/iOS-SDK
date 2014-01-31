#import "STRAdYouTube.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdYouTubeSpec)

describe(@"STRAdYouTube", ^{
    __block STRAdYouTube *ad;

    beforeEach(^{
        ad = [STRAdYouTube new];
        ad.mediaURL = [NSURL URLWithString:@"http://www.youtube.com/watch?v=BWAK0J8Uhzk"];
    });

    it(@"can return the youtube video id based on the media url", ^{
        [ad youtubeVideoId] should equal(@"BWAK0J8Uhzk");
    });
});

SPEC_END
