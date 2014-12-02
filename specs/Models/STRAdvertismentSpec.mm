#import "STRAdvertisement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdvertisementSpec)

describe(@"STRAdvertisement", ^{
    __block STRAdvertisement *ad;

    beforeEach(^{
        ad = [STRAdvertisement new];
        ad.advertiser = @"ginny minis";
    });

    it(@"has a sponsored by method that prefixes the 'Promoted by' string", ^{
        [ad sponsoredBy] should equal(@"Promoted by ginny minis");
    });

    describe(@"-platformLogoForWidth", ^{
        it(@"returns a UIImageView with the Image set to the centerImage", ^{
        });

        it(@"returns a view with a maximum size of the platform logo", ^{
        });

        it(@"returns a view with a minimum size of 24", ^{
        });
    });
});

SPEC_END
