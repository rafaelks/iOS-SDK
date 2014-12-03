#import "STRAdvertisement.h"
#import "STRImages.h"

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
            char imageData[100];
            [UIImagePNGRepresentation([ad platformLogoForWidth:100.0].image) getBytes:&imageData length:100];

            char expectedData[100];
            [UIImagePNGRepresentation([STRImages playBtn]) getBytes:&expectedData length:100];
            imageData should equal(expectedData);
        });

        it(@"returns a view with a maximum size of the platform logo", ^{
            UIImageView *logoView = [ad platformLogoForWidth:1000.0];
            logoView.frame.size.width should equal([STRImages playBtn].size.width/2);
        });

        it(@"returns a view with a minimum size of 24", ^{
            UIImageView *logoView = [ad platformLogoForWidth:10.0];
            logoView.frame.size.width should equal(24);
        });
    });
});

SPEC_END
