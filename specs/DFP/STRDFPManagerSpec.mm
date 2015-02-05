#import "STRSpecModule.h"
#import <objc/runtime.h>

#import "STRDFPManager.h"
#import "STRDFPAppModule.h"
#import "STRAdGenerator.h"
#import "STRAdPlacement.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(DFPManagerSpec)

describe(@"DFPManager", ^{
    __block STRInjector *injector;
    __block STRDFPManager *dfpManager;
    __block STRAdGenerator *generator;
    __block STRAdPlacement *adPlacement;
    __block id<STRAdViewDelegate> delegate;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRDFPAppModule new]];
        dfpManager = [STRDFPManager sharedInstance];
        dfpManager.injector = injector;

        generator = nice_fake_for([STRAdGenerator class]);
        [injector bind:[STRAdGenerator class] toInstance:generator];

        delegate = nice_fake_for(@protocol(STRAdViewDelegate));

        adPlacement = [[STRAdPlacement alloc] initWithAdView:nil
                                                PlacementKey:@"placementKey"
                                    presentingViewController:nil
                                                    delegate:delegate
                                                     adIndex:0
                                                     DFPPath:@"DFPPath"
                                                 DFPDeferred:nil];
    });

    context(@"-renderCreative:inPlacement", ^{
        beforeEach(^{
            [dfpManager cacheAdPlacement:adPlacement];
        });

        context(@"when the creative key is for monetize", ^{
            describe(@"when the placement deferred is not set", ^{
                __block STRDeferred *generatorDeferred;
                __block STRPromise *managerPromise;

                beforeEach(^{
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(placeAdInPlacement:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderCreative:@"STX_MONETIZE" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(placeAdInPlacement:));
                });

                describe(@"when the promise resolves successfully", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred resolveWithValue:nil];
                    });

                    it(@"resolves its promise", ^{
                        managerPromise should have_received(@selector(resolveWithValue:));
                    });
                });

                describe(@"when the promise is rejected", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred rejectWithError:nil];
                    });

                    it(@"rejects its promise", ^{
                        managerPromise should have_received(@selector(rejectWithError:));
                    });
                });
            });

            describe(@"when the placement deferred is set", ^{
                __block STRDeferred *generatorDeferred;
                __block STRPromise *managerPromise;
                __block STRDeferred *adDeferred;

                beforeEach(^{
                    adDeferred = nice_fake_for([STRDeferred class]);
                    adPlacement.DFPDeferred = adDeferred;
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(prefetchAdForPlacement:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderCreative:@"STX_MONETIZE" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(prefetchAdForPlacement:));
                });

                describe(@"when the promise resolves successfully", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred resolveWithValue:nil];
                    });

                    it(@"resolves the placements deferred", ^{
                        adDeferred should have_received(@selector(resolveWithValue:));
                    });

                    it(@"resolves its promise", ^{
                        managerPromise should have_received(@selector(resolveWithValue:));
                    });
                });
                
                describe(@"when the promise is rejected", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred rejectWithError:nil];
                    });

                    it(@"rejects the placements deferred", ^{
                        adDeferred should have_received(@selector(rejectWithError:));
                    });

                    it(@"rejects its promise", ^{
                        managerPromise should have_received(@selector(rejectWithError:));
                    });
                });
            });
        });

        context(@"when the creative key is for a specific creative", ^{
            describe(@"when the placement deferred is not set", ^{
                __block STRDeferred *generatorDeferred;
                __block STRPromise *managerPromise;

                beforeEach(^{
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(placeCreative:inPlacement:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderCreative:@"creativeKey" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(placeCreative:inPlacement:));
                });

                describe(@"when the promise resolves successfully", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred resolveWithValue:nil];
                    });

                    it(@"resolves its promise", ^{
                        managerPromise should have_received(@selector(resolveWithValue:));
                    });
                });

                describe(@"when the promise is rejected", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred rejectWithError:nil];
                    });

                    it(@"rejects its promise", ^{
                        managerPromise should have_received(@selector(rejectWithError:));
                    });
                });
            });

            describe(@"when the placement deferred is set", ^{
                __block STRDeferred *generatorDeferred;
                __block STRPromise *managerPromise;
                __block STRDeferred *adDeferred;

                beforeEach(^{
                    adDeferred = nice_fake_for([STRDeferred class]);
                    adPlacement.DFPDeferred = adDeferred;
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(prefetchCreative:forPlacement:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderCreative:@"creativeKey" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(prefetchCreative:forPlacement:));
                });

                describe(@"when the promise resolves successfully", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred resolveWithValue:nil];
                    });

                    it(@"resolves the placements deferred", ^{
                        adDeferred should have_received(@selector(resolveWithValue:));
                    });

                    it(@"resolves its promise", ^{
                        managerPromise should have_received(@selector(resolveWithValue:));
                    });
                });

                describe(@"when the promise is rejected", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred rejectWithError:nil];
                    });

                    it(@"rejects the placements deferred", ^{
                        adDeferred should have_received(@selector(rejectWithError:));
                    });

                    it(@"rejects its promise", ^{
                        managerPromise should have_received(@selector(rejectWithError:));
                    });
                });
            });
        });
    });
});

SPEC_END
