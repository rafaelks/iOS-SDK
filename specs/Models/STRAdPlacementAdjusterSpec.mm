#import "STRAdPlacementAdjuster.h"
#import "STRAdCache.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdPlacementAdjusterSpec)

describe(@"STRAdPlacementAdjuster", ^{
    __block STRAdPlacementAdjuster *adjuster;
    __block STRAdCache *fakeAdCache;
    __block NSString *fakePlacementKey;

    beforeEach(^{
        fakeAdCache = nice_fake_for([STRAdCache class]);
        fakePlacementKey = @"fake-placement-key";
    });
    
    describe(@"When an ad is loaded", ^{
        beforeEach(^{
            fakeAdCache stub_method(@selector(numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:)).and_return((long)5);
            fakeAdCache stub_method(@selector(isAdAvailableForPlacement:AndInitializeAd:)).and_return(YES);

            adjuster = [STRAdPlacementAdjuster adjusterInSection:0
                                           articlesBeforeFirstAd:5
                                              articlesBetweenAds:5
                                                    placementKey:fakePlacementKey
                                                         adCache:fakeAdCache];
            adjuster.numContentRows = 10;
        });
        
        describe(@"+adjusterInSection:articlesBeforeFirstAd:articlesBetweenAds:", ^{
            it(@"throws an exception if articles between ads is less than or equal to 0", ^{
                expect(^{
                    [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:0 articlesBetweenAds:0 placementKey:fakePlacementKey adCache:fakeAdCache];
                }).to(raise_exception);
            });

            it(@"throws an exception if articles before first ad is less than 0", ^{
                expect(^{
                    [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:-1 articlesBetweenAds:0 placementKey:fakePlacementKey adCache:fakeAdCache];
                }).to(raise_exception);
            });
        });

        describe(@"-isAdAtIndexPath:", ^{
            it(@"returns YES if it's the index path of the first ad", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]] should be_truthy;
            });

            it(@"returns YES if it's a subsequet ad position", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:11 inSection:0]] should be_truthy;
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:17 inSection:0]] should be_truthy;
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:23 inSection:0]] should be_truthy;
            });

            it(@"returns NO if it's not in the ad section", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_falsy;
            });
        });
        
        describe(@"-indexPathWithoutAds:", ^{
            it(@"leaves indexPath unchanged if it's not an ad slot", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"returns nil if the index path is equal to an adIndexPath", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:5 inSection:0]] should be_nil;
            });
            
            it(@"subtracts indexPath for cells after ad row in same section", ^{
                fakeAdCache stub_method(@selector(assignedAdIndixesForPlacementKey:)).and_return(@[[NSNumber numberWithInt:5]]);
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:6 inSection:0]] should equal([NSIndexPath indexPathForRow:5 inSection:0]);
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:10 inSection:0]] should equal([NSIndexPath indexPathForRow:9 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil index path", ^{
                [adjuster indexPathWithoutAds:nil] should be_nil;
            });
        });
        
        describe(@"-indexPathsWithoutAds", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                            [NSIndexPath indexPathForRow:5 inSection:0]];
                
                [adjuster indexPathsWithoutAds:trueIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:1 inSection:0]]);
                
            });
        });

        describe(@"-indexPathIncludingAds:", ^{
            beforeEach(^{
                fakeAdCache stub_method(@selector(assignedAdIndixesForPlacementKey:)).and_return(@[[NSNumber numberWithInt:5]]);
            });

            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"increments indexPath if it's equal to adIndexPath", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:5 inSection:0]] should equal([NSIndexPath indexPathForRow:6 inSection:0]);
            });
            
            it(@"increments indexPath for cells after ad row in same section", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:6 inSection:0]] should equal([NSIndexPath indexPathForRow:7 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil indexPath", ^{
                [adjuster indexPathIncludingAds:nil] should be_nil;
            });
        });

        describe(@"-indexPathsIncludingAds", ^{
            beforeEach(^{
                fakeAdCache stub_method(@selector(assignedAdIndixesForPlacementKey:)).and_return(@[[NSNumber numberWithInt:5]]);
            });
            it(@"adjusts all of the index paths", ^{
                NSArray *externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                                [NSIndexPath indexPathForRow:5 inSection:0],
                                                [NSIndexPath indexPathForRow:6 inSection:0]];
                
                [adjuster indexPathsIncludingAds:externalIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:6 inSection:0],
                                                                            [NSIndexPath indexPathForRow:7 inSection:0]]);
            });
        });
        
        describe(@"-numberOfAdsInSection:gienNumberOfRows:", ^{
            it(@"returns 0 if not the ad section", ^{
                adjuster.numContentRows = 100;
                [adjuster numberOfAdsInSection:1] should equal(0);
            });
            
            it(@"returns 0 if there are less articles than the number before an ad should be shown", ^{
                adjuster.numContentRows = 4;
                [adjuster numberOfAdsInSection:0] should equal(0);
            });
            
            it(@"correctly calculates the number of ads based on the number of ads in the section", ^{
                adjuster.numContentRows = 9;
                [adjuster numberOfAdsInSection:0] should equal(1);
                adjuster.numContentRows = 10;
                [adjuster numberOfAdsInSection:0] should equal(2);
                adjuster.numContentRows = 11;
                [adjuster numberOfAdsInSection:0] should equal(2);
                adjuster.numContentRows = 12;
                [adjuster numberOfAdsInSection:0] should equal(2);
                adjuster.numContentRows = 13;
                [adjuster numberOfAdsInSection:0] should equal(2);
                adjuster.numContentRows = 14;
                [adjuster numberOfAdsInSection:0] should equal(2);
                adjuster.numContentRows = 15;
                [adjuster numberOfAdsInSection:0] should equal(3);
            });

            it(@"handles edge cases", ^{
                STRAdPlacementAdjuster *everyOtherAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:0 articlesBetweenAds:1 placementKey:fakePlacementKey adCache:fakeAdCache];
                everyOtherAdjuster.numContentRows = 3;
                [everyOtherAdjuster numberOfAdsInSection:0] should equal(4);

                STRAdPlacementAdjuster *onlyOneAd = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:NSIntegerMax placementKey:fakePlacementKey adCache:fakeAdCache];

                onlyOneAd.numContentRows = 10000;
                [onlyOneAd numberOfAdsInSection:0] should equal(1);
            });
        });
        
        describe(@"-getLastCalculatedNumberOfAdsInSection:", ^{
            it(@"returns 0 if not already calculated", ^{
                [adjuster getLastCalculatedNumberOfAdsInSection:0] should equal(0);
            });
        });
  
        describe(@"-willMoveRowAtExternalIndexPath:toExternalIndexPath:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                fakeAdCache stub_method(@selector(assignedAdIndixesForPlacementKey:)).and_return(@[[NSNumber numberWithInt:1]]);
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            sharedExamplesFor(@"moving a row", ^(NSDictionary *sharedContext) {
                __block NSArray *trueIndexPaths;
                __block NSIndexPath *externalStartIndex;
                __block NSIndexPath *externalFinalIndex;
                
                beforeEach(^{
                    externalStartIndex = sharedContext[@"externalStartIndex"];
                    externalFinalIndex = sharedContext[@"externalFinalIndex"];
                    trueIndexPaths = [multiSectionAdjuster willMoveRowAtExternalIndexPath:externalStartIndex
                                                                      toExternalIndexPath:externalFinalIndex];
                });
                
                it(@"returns the true index of the start position", ^{
                    NSInteger startRow = externalStartIndex.row + [sharedContext[@"expectedChangeToStartRow"] integerValue];
                    NSIndexPath *expectedStartPath = [NSIndexPath indexPathForRow:startRow inSection:externalStartIndex.section];
                    
                    [trueIndexPaths firstObject] should equal(expectedStartPath);
                });
                
                it(@"returns the true index of the end position", ^{
                    NSInteger finalRow = externalFinalIndex.row + [sharedContext[@"expectedChangeToFinalRow"] integerValue];
                    NSIndexPath *expectedFinalPath = [NSIndexPath indexPathForRow:finalRow inSection:externalFinalIndex.section];
                    
                    [trueIndexPaths lastObject] should equal(expectedFinalPath);
                });
            });
            
            describe(@"moving from an ad section to an ad section", ^{
                describe(@"(AFTER -> BEFORE) handles moving to an index path that is before an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @1;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(AFTER -> SAME AS AD) handles moving from an index path after an ad to an index path that is an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @1;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @1;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(BEFORE -> AFTER)handles moving from an index path before an ad to an index path that is after an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @1;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(AFTER -> AFTER) handles moving from an index path to an index path, when are both after the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @1;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @1;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(BEFORE -> BEFORE) handles moving from an index path to an index path, when both are after the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                        
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
            });
            
            describe(@"moving from an ad section to a non-ad section", ^{
                describe(@"(BEFORE -> NEW SECTION)moving from before the ad to another section", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(AFTER -> NEW SECTION)moving from after the ad to another section", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @1;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
            });
            
            describe(@"moving from a non-ad section to an ad section", ^{
                describe(@"(NON-AD SECTION -> BEFORE AD)moving from some section to the ad's section, before the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:1];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(NON-AD SECTION -> AFTER AD)moving from some section to the ad's section, after the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:1];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @1;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
            });
            
            describe(@"moving from a non-ad section to a non-ad section", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    
                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                    sharedContext[@"expectedChangeToStartRow"] = @0;
                    
                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:2];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });
                
                itShouldBehaveLike(@"moving a row");
            });
        });

        describe(@"-willDeleteSections:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            describe(@"when some of the sections around the ad section are being deleted", ^{
                it(@"moves up the ad section by the appropriate amount", ^{
                    multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:2 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(0);
                });
            });
            
            describe(@"when one of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(-1);
                });
            });
            
            describe(@"when none of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:1];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(0);
                });
            });
            
            describe(@"when the section containing the ad has already been deleted", ^{
                beforeEach(^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                });
                
                it(@"keeps the same nonexistant ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(-1);
                });
            });
        });

        describe(@"-willInsertSections:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:1 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            describe(@"when some of the sections around the ad section are being inserting", ^{
                it(@"moves down the ad section by the appropriate amount", ^{
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willInsertSections:indices];
                    multiSectionAdjuster.adSection should equal(3);
                });
            });
        });

        describe(@"-willMoveSection:toSection:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:1 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            describe(@"moving a section that is before the ad section", ^{
                describe(@"to still be before the ad section", ^{
                    beforeEach(^{
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:2 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
                    });
                    
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:1];
                        multiSectionAdjuster.adSection should equal(2);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adSection should equal(0);
                    });
                });
                
                describe(@"to be after the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adSection should equal(0);
                    });
                });
            });
            
            describe(@"moving a section that is after the ad section", ^{
                describe(@"to be before the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:0];
                        multiSectionAdjuster.adSection should equal(2);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:1];
                        multiSectionAdjuster.adSection should equal(2);
                    });
                    
                });
                
                describe(@"to still be after the ad section", ^{
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:3 toSection:2];
                        multiSectionAdjuster.adSection should equal(1);
                    });
                });
            });
            
            describe(@"moving the ad section", ^{
                it(@"adjusts the ad section to be the new place", ^{
                    [multiSectionAdjuster willMoveSection:1 toSection:5];
                    multiSectionAdjuster.adSection should equal(5);
                });
            });
        });
    });
    
    describe(@"When an ad is not loaded", ^{
        beforeEach(^{
            adjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            adjuster.numContentRows = 10;
        });
        
        describe(@"-isAdAtIndexPath:", ^{
            it(@"returns NO if indexPaths match", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_falsy;
            });
        });

        describe(@"-indexPathWithoutAds:", ^{
            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"returns the original index path if the index path is equal to adIndexPath", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:1 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"returns the original index path for cells after ad row in same section", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:9 inSection:0]] should equal([NSIndexPath indexPathForRow:9 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster indexPathWithoutAds:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil index path", ^{
                [adjuster indexPathWithoutAds:nil] should be_nil;
            });
        });

        describe(@"-indexPathsWithoutAds", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                            [NSIndexPath indexPathForRow:2 inSection:0]];
                
                [adjuster indexPathsWithoutAds:trueIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                                                            [NSIndexPath indexPathForRow:2 inSection:0]]);
                
            });
        });

        describe(@"-indexPathIncludingAds:", ^{
            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"returns the original indexPath if it's equal to adIndexPath", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:1 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"returns the original indexPath for cells after ad row in same section", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster indexPathIncludingAds:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil indexPath", ^{
                [adjuster indexPathIncludingAds:nil] should be_nil;
            });
        });

        describe(@"-indexPathsIncludingAds", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                                [NSIndexPath indexPathForRow:1 inSection:0],
                                                [NSIndexPath indexPathForRow:2 inSection:0]];
                
                [adjuster indexPathsIncludingAds:externalIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                                                            [NSIndexPath indexPathForRow:2 inSection:0]]);
            });
        });
        
        describe(@"-numberOfAdsInSection:gienNumberOfRows:", ^{
            it(@"returns 0 ads", ^{
                adjuster.numContentRows = 100;
                [adjuster numberOfAdsInSection:0] should equal(0);
            });
        });
        
        describe(@"-getLastCalculatedNumberOfAdsInSection:", ^{
            it(@"returns 0 ads for all sections", ^{
                [adjuster getLastCalculatedNumberOfAdsInSection:0] should equal(0);
                [adjuster getLastCalculatedNumberOfAdsInSection:1] should equal(0);
                [adjuster getLastCalculatedNumberOfAdsInSection:10] should equal(0);
            });
        });

        describe(@"-willMoveRowAtExternalIndexPath:toExternalIndexPath:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            sharedExamplesFor(@"moving a row", ^(NSDictionary *sharedContext) {
                __block NSArray *trueIndexPaths;
                __block NSIndexPath *externalStartIndex;
                __block NSIndexPath *externalFinalIndex;
                
                beforeEach(^{
                    externalStartIndex = sharedContext[@"externalStartIndex"];
                    externalFinalIndex = sharedContext[@"externalFinalIndex"];
                    trueIndexPaths = [multiSectionAdjuster willMoveRowAtExternalIndexPath:externalStartIndex
                                                                      toExternalIndexPath:externalFinalIndex];
                });

                it(@"returns the true index of the start position", ^{
                    NSInteger startRow = externalStartIndex.row + [sharedContext[@"expectedChangeToStartRow"] integerValue];
                    NSIndexPath *expectedStartPath = [NSIndexPath indexPathForRow:startRow inSection:externalStartIndex.section];

                    [trueIndexPaths firstObject] should equal(expectedStartPath);
                    
                });

                it(@"returns the true index of the end position", ^{
                    NSInteger finalRow = externalFinalIndex.row + [sharedContext[@"expectedChangeToFinalRow"] integerValue];
                    NSIndexPath *expectedFinalPath = [NSIndexPath indexPathForRow:finalRow inSection:externalFinalIndex.section];
                    
                    [trueIndexPaths lastObject] should equal(expectedFinalPath);
                });
            });
            
            describe(@"moving from an ad section to an ad section", ^{
                describe(@"(AFTER -> BEFORE) handles moving to an index path that is before an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];

                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(AFTER -> SAME AS AD) handles moving from an index path after an ad to an index path that is an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(BEFORE -> AFTER)handles moving from an index path before an ad to an index path that is after an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(AFTER -> AFTER) handles moving from an index path to an index path, when are both after the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(BEFORE -> BEFORE) handles moving from an index path to an index path, when both are after the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                        
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
            });
            
            describe(@"moving from an ad section to a non-ad section", ^{
                describe(@"(BEFORE -> NEW SECTION)moving from before the ad to another section", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(AFTER -> NEW SECTION)moving from after the ad to another section", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
            });
            
            describe(@"moving from a non-ad section to an ad section", ^{
                describe(@"(NON-AD SECTION -> BEFORE AD)moving from some section to the ad's section, before the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:1];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(NON-AD SECTION -> AFTER AD)moving from some section to the ad's section, after the ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:1];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
            });
            
            describe(@"moving from a non-ad section to a non-ad section", ^{
                beforeEach(^{
                    NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                    sharedContext[@"expectedChangeToAdRow"] = @0;
                    
                    sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:0 inSection:1];
                    sharedContext[@"expectedChangeToStartRow"] = @0;
                    
                    sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:2];
                    sharedContext[@"expectedChangeToFinalRow"] = @0;
                });
                
                itShouldBehaveLike(@"moving a row");
            });
        });

        describe(@"-willDeleteSections:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            describe(@"when some of the sections around the ad section are being deleted", ^{
                it(@"moves up the ad section by the appropriate amount", ^{
                    multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:2 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(0);
                });
            });
            
            describe(@"when one of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(-1);
                });
            });
            
            describe(@"when none of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:1];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(0);
                });
            });
            
            describe(@"when the section containing the ad has already been deleted", ^{
                beforeEach(^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                });
                
                it(@"keeps the same nonexistant ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adSection should equal(-1);
                });
            });
        });

        describe(@"-willInsertSections:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:1 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            describe(@"when some of the sections around the ad section are being inserting", ^{
                it(@"moves down the ad section by the appropriate amount", ^{
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willInsertSections:indices];
                    multiSectionAdjuster.adSection should equal(3);
                });
            });
        });

        describe(@"-willMoveSection:toSection:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:1 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
            });
            
            describe(@"moving a section that is before the ad section", ^{
                describe(@"to still be before the ad section", ^{
                    beforeEach(^{
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:2 articlesBeforeFirstAd:1 articlesBetweenAds:5 placementKey:fakePlacementKey adCache:fakeAdCache];
                    });
                    
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:1];
                        multiSectionAdjuster.adSection should equal(2);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adSection should equal(0);
                    });
                });
                
                describe(@"to be after the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adSection should equal(0);
                    });
                });
            });
            
            describe(@"moving a section that is after the ad section", ^{
                describe(@"to be before the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:0];
                        multiSectionAdjuster.adSection should equal(2);
//                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:1];
                        multiSectionAdjuster.adSection should equal(2);
//                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                    
                });
                
                describe(@"to still be after the ad section", ^{
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:3 toSection:2];
                        multiSectionAdjuster.adSection should equal(1);
//                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
                    });
                });
            });
            
            describe(@"moving the ad section", ^{
                it(@"adjusts the ad section to be the new place", ^{
                    [multiSectionAdjuster willMoveSection:1 toSection:5];
                    multiSectionAdjuster.adSection should equal(5);
//                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:5]);
                });
            });
        });
    });
});

SPEC_END
