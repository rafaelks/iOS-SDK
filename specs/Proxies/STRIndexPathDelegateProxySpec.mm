#import "STRIndexPathDelegateProxy.h"
#import "STRAdPlacementAdjuster.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRIndexPathDelegateProxySpec)

describe(@"STRIndexPathDelegateProxy", ^{
    __block STRIndexPathDelegateProxy *proxy;
    __block id<UITableViewDelegate> delegate;
    __block STRAdPlacementAdjuster *adjuster;

    beforeEach(^{
        delegate = nice_fake_for(@protocol(UITableViewDelegate));
        adjuster = [STRAdPlacementAdjuster new];
        proxy = [[STRIndexPathDelegateProxy alloc] initWithOriginalDelegate:delegate
                                                        adPlacementAdjuster:adjuster
                                                                   adHeight:23];
    });

    describe(@"-copyWithNewDelegate:", ^{
        it(@"returns a delegateProxy with all same values except new delegate", ^{
            id<UITableViewDelegate>newDelegate = nice_fake_for(@protocol(UITableViewDelegate));
            STRIndexPathDelegateProxy *newProxy = [proxy copyWithNewDelegate:newDelegate];
            newProxy should_not be_same_instance_as(proxy);
            newProxy.originalDelegate should be_same_instance_as(newDelegate);
            newProxy.adPlacementAdjuster should be_same_instance_as(adjuster);
            newProxy.adHeight should equal(23);
        });
    });
});

SPEC_END
