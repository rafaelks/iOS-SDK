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

    describe(@"-sponsoredBy", ^{
        describe(@"when there is no promoted by text", ^{
            it(@"has a sponsored by method that prefixes the 'Promoted by' string", ^{
                [ad sponsoredBy] should equal(@"Promoted by ginny minis");
            });
        });

        describe(@"when there is promoted by text", ^{
            beforeEach(^{
                ad.promotedByText = @"Sponsored by";
            });

            it(@"has a sponsored by method that prefixes the 'Promoted by' string", ^{
                [ad sponsoredBy] should equal(@"Sponsored by ginny minis");
            });
        });
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

    describe(@"-optOutUrl", ^{
        describe(@"when the DSP opt our url is not present", ^{
            it(@"returns just the platform url", ^{
                NSURL *expected = [NSURL URLWithString:@"http://platform-cdn.sharethrough.com/privacy-policy.html"];
                [ad optOutUrl] should equal(expected);
            });
        });

        describe(@"when the DSP opt our url is present", ^{
            beforeEach(^{
                ad.optOutText = @"This is some privacy info";
                ad.optOutUrlString = @"https://example.co/privacy";
            });

            it(@"returns the url with the encoded params", ^{
                NSURL *expected = [NSURL URLWithString:@"http://platform-cdn.sharethrough.com/privacy-policy.html?opt_out_url=https%3A%2F%2Fexample.co%2Fprivacy&opt_out_text=This%20is%20some%20privacy%20info"];
                NSURL *actual = [ad optOutUrl];
                actual should equal(expected);
            });
        });
    });
});

SPEC_END
