#import "STRAdGenerator.h"
#import "STRAdViewFixture.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdGeneratorSpec)

describe(@"STRAdGenerator", ^{
    __block STRAdGenerator *generator;

    beforeEach(^{
        generator = [STRAdGenerator new];
    });

    it(@"can add placeholder data onto the passed in view", ^{
        STRAdViewFixture *view = [STRAdViewFixture new];
        [generator placeAdInView:view];

        view.adTitle.text should equal(@"Ad title, from SDK");
        view.adDescription.text should equal(@"Ad description, from SDK");
        view.adThumbnail.image should equal([UIImage imageNamed:@"STRResources.bundle/images/fixture_image.png"]);
    });
});

SPEC_END
