#import "STRSpecModule.h"
#import <objc/runtime.h>

#import "STRDFPGridlikeViewDataSourceProxy.h"
#import "STRDFPAppModule.h"
#import "STRDFPAdGenerator.h"
#import "STRAdPlacement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(DFPGridlikeDataSourceProxy)

/* describe(@"DFPManager", ^{
    __block STRInjector *injector;
    __block STRDFPAdGenerator *generator;
    __block STRDFPGridlikeViewDataSourceProxy *dataSourceProxy;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRDFPAppModule new]];

        generator = nice_fake_for([STRDFPAdGenerator class]);

        [injector bind:[STRDFPAdGenerator class] toInstance:generator];

        dataSourceProxy = [[STRDFPGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"cell"
                                                                                      placementKey:@"placementKey"
                                                                          presentingViewController:nil
                                                                                          injector:injector];
    });

    context(@"-prefetchAdForGridLikeView:", ^{
        __block id gridlikeview;

        beforeEach(^{
        });

        describe(@"placing in a UITableView", ^{
            beforeEach(^{
                gridlikeview = [[UITableView alloc] init];
            });

            it(@"calls the generator to place the ad in placement", ^{
                [dataSourceProxy prefetchAdForGridLikeView:gridlikeview];
                generator should have_received(@selector(placeAdInPlacement:));
            });
        });

        describe(@"placing in a UICollectionView", ^{
            beforeEach(^{
                gridlikeview = nice_fake_for([UICollectionView class]);
            });

            it(@"calls the generator to place the ad in placement", ^{
                [dataSourceProxy prefetchAdForGridLikeView:gridlikeview];
                generator should have_received(@selector(placeAdInPlacement:));
            });

            describe(@"resolving the placement's deferred", ^{
                __block STRAdPlacement *placement;
                beforeEach(^{
                    generator stub_method(@selector(placeAdInPlacement:)).and_do(^(NSInvocation *invocation) {
                        [invocation getArgument:&placement atIndex:0];
                        [placement.DFPDeferred resolveWithValue:nil];
                    });

                    it(@"reloads the gridlike view", ^{
                        gridlikeview should have_received(@selector(reloadData));
                    });
                });
            });

            describe(@"reject the placement's deferred", ^{
                __block STRAdPlacement *placement;
                beforeEach(^{
                    generator stub_method(@selector(placeAdInPlacement:)).and_do(^(NSInvocation *invocation) {
                        [invocation getArgument:&placement atIndex:0];
                        [placement.DFPDeferred rejectWithError:nil];
                    });

                    it(@"reloads the gridlike view", ^{
                        gridlikeview should_not have_received(@selector(reloadData));
                    });
                });
            });
        });

        describe(@"placing in a non-gridlike view", ^{
            beforeEach(^{
                gridlikeview = [[UIView alloc] init];
            });

            it(@"does not call the generator to place the ad in placement", ^{
                [dataSourceProxy prefetchAdForGridLikeView:gridlikeview];
                generator should_not have_received(@selector(placeAdInPlacement:));
            });
        });
    });
}); */

SPEC_END
