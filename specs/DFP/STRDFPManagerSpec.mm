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
                                                isDirectSold:YES
                                                     DFPPath:@"DFPPath"
                                                 DFPDeferred:nil];
    });

    context(@"-renderAdForParameter", ^{
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
                    managerPromise = [dfpManager renderAdForParameter:@"STX_MONETIZE" inPlacement:@"DFPPath"];
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
                    managerPromise = [dfpManager renderAdForParameter:@"STX_MONETIZE" inPlacement:@"DFPPath"];
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
                    generator stub_method(@selector(placeAdInPlacement:auctionParameterKey:auctionParameterValue:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderAdForParameter:@"creative_key=12345678" inPlacement:@"DFPPath"];
                });

                it(@"calls placeAdInPlacement:auctionParameterKey in the generator", ^{
                    generator should have_received(@selector(placeAdInPlacement:auctionParameterKey:auctionParameterValue:)).with(adPlacement, @"creative_key", @"12345678");;
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
                    generator stub_method(@selector(prefetchForPlacement:auctionParameterKey:auctionParameterValue:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderAdForParameter:@"creative_key=12345678" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(prefetchForPlacement:auctionParameterKey:auctionParameterValue:)).with(adPlacement, @"creative_key", @"12345678");;
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

        context(@"when the campaign key is for a specific campaign", ^{
            describe(@"when the placement deferred is not set", ^{
                __block STRDeferred *generatorDeferred;
                __block STRPromise *managerPromise;

                beforeEach(^{
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(placeAdInPlacement:auctionParameterKey:auctionParameterValue:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderAdForParameter:@"campaign_key=12345678" inPlacement:@"DFPPath"];
                });

                it(@"calls placeAdInPlacement:auctionParameterKey in the generator", ^{
                    generator should have_received(@selector(placeAdInPlacement:auctionParameterKey:auctionParameterValue:)).with(adPlacement, @"campaign_key", @"12345678");
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
                    generator stub_method(@selector(prefetchForPlacement:auctionParameterKey:auctionParameterValue:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderAdForParameter:@"campaign_key=12345678" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(prefetchForPlacement:auctionParameterKey:auctionParameterValue:)).with(adPlacement, @"campaign_key", @"12345678");
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

        context(@"when it's the old style of creative key", ^{
            describe(@"when the placement deferred is not set", ^{
                __block STRDeferred *generatorDeferred;
                __block STRPromise *managerPromise;

                beforeEach(^{
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(placeAdInPlacement:auctionParameterKey:auctionParameterValue:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderAdForParameter:@"12345678" inPlacement:@"DFPPath"];
                });

                it(@"calls placeAdInPlacement:auctionParameterKey in the generator", ^{
                    generator should have_received(@selector(placeAdInPlacement:auctionParameterKey:auctionParameterValue:)).with(adPlacement, @"creative_key", @"12345678");
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
                __block NSObject *returnedObject;

                beforeEach(^{
                    returnedObject = [NSObject new];
                    adDeferred = nice_fake_for([STRDeferred class]);
                    adPlacement.DFPDeferred = adDeferred;
                    generatorDeferred = [STRDeferred defer];
                    generator stub_method(@selector(prefetchForPlacement:auctionParameterKey:auctionParameterValue:)).and_return(generatorDeferred.promise);
                    managerPromise = [dfpManager renderAdForParameter:@"12345678" inPlacement:@"DFPPath"];
                });

                it(@"calls placeCreative:inPlacement in the generator", ^{
                    generator should have_received(@selector(prefetchForPlacement:auctionParameterKey:auctionParameterValue:)).with(adPlacement, @"creative_key", @"12345678");
                });

                describe(@"when the promise resolves successfully", ^{
                    beforeEach(^{
                        spy_on(managerPromise);
                        [generatorDeferred resolveWithValue:returnedObject];
                    });

                    it(@"resolves the placements deferred", ^{
                        adDeferred should have_received(@selector(resolveWithValue:)).with(returnedObject);
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
