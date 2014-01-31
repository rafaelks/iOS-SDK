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
});

SPEC_END
