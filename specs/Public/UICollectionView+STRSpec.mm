#import "UICollectionView+STR.h"
#import "STRCollectionViewDataSource.h"
#import "STRCollectionViewCell.h"
#import "STRAdPlacementAdjuster.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRCollectionViewAdGenerator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(UICollectionViewSpec)

describe(@"UICollectionView+STR", ^{
    __block UICollectionView *collectionView;
    __block STRCollectionViewDataSource *dataSource;
    __block STRAdPlacementAdjuster *adPlacementAdjuster;

    beforeEach(^{
        collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 420) collectionViewLayout:[UICollectionViewFlowLayout new]];

        dataSource = [[STRCollectionViewDataSource alloc] init];
        dataSource.itemsForEachSection = @[@3, @3];

        collectionView.dataSource = dataSource;

        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"adCellReuseIdentifier"];
        [collectionView registerClass:[STRCollectionViewCell class] forCellWithReuseIdentifier:@"identifier"];

        adPlacementAdjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        spy_on(adPlacementAdjuster);

        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        [injector bind:[STRAdGenerator class] toInstance:nice_fake_for([STRAdGenerator class])];

        spy_on([STRAdPlacementAdjuster class]);
        [STRAdPlacementAdjuster class] stub_method(@selector(adjusterWithInitialAdIndexPath:)).and_return(adPlacementAdjuster);

        STRCollectionViewAdGenerator *generator = [injector getInstance:[STRCollectionViewAdGenerator class]];
        [generator placeAdInCollectionView:collectionView
                     adCellReuseIdentifier:@"adCellReuseIdentifier"
                              placementKey:@"placementKey"
                  presentingViewController:nil];

        [collectionView reloadData];
    });

    describe(@"-str_dequeueReusableCellWithIdentifier:forIndexPath", ^{
        describe(@"when the collection view has not been configured with an ad", ^{
            __block UICollectionView *noAdCollectionView;

            beforeEach(^{
                noAdCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) collectionViewLayout:[UICollectionViewFlowLayout new]];
            });

            it(@"raises an exception", ^{
                expect(^{
                    [noAdCollectionView str_dequeueReusableCellWithReuseIdentifier:@"cellIdentifier"
                                                                      forIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                }).to(raise_exception);
            });
        });

        describe(@"when the collection view has been configured to display an ad", ^{
            context(@"when the index path is before the ad index path", ^{
                beforeEach(^{
                    spy_on(collectionView);

                    [collectionView str_dequeueReusableCellWithReuseIdentifier:@"identifier" forIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] should_not be_nil;
                });

                it(@"calls through to original dequeue method without changing index path", ^{
                    collectionView should have_received(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:))
                    .with(@"identifier", [NSIndexPath indexPathForItem:0 inSection:0]);
                });
            });

            context(@"when the index path is after the ad index path", ^{
                beforeEach(^{
                    spy_on(collectionView);

                    [collectionView str_dequeueReusableCellWithReuseIdentifier:@"identifier" forIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]] should_not be_nil;
                });

                it(@"calls through to original dequeue method after changing index path", ^{
                    collectionView should have_received(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:))
                    .with(@"identifier", [NSIndexPath indexPathForItem:3 inSection:0]);
                });
            });

        });
    });


});

SPEC_END
