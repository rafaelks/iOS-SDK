#import "STRAdPlacementAdjuster.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRAdPlacementAdjusterSpec)
/*
describe(@"STRAdPlacementAdjuster", ^{
    __block STRAdPlacementAdjuster *adjuster;
    
    describe(@"When an ad is loaded", ^{
        beforeEach(^{
            adjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            adjuster.adLoaded = YES;
        });
        
        describe(@"-isAdAtIndexPath:", ^{
            it(@"returns YES if indexPaths match", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_truthy;
            });
            
            it(@"returns NO if indexPaths match", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]] should be_falsy;
            });
        });
        
        describe(@"-externalIndexPath:", ^{
            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"returns nil if the index path is equal to adIndexPath", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_nil;
            });
            
            it(@"subtracts indexPath for cells after ad row in same section", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil index path", ^{
                [adjuster externalIndexPath:nil] should be_nil;
            });
        });
        
        describe(@"-externalIndexPaths", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                            [NSIndexPath indexPathForRow:2 inSection:0]];
                
                [adjuster externalIndexPaths:trueIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:1 inSection:0]]);
                
            });
        });
        
        describe(@"-trueIndexPath:", ^{
            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"increments indexPath if it's equal to adIndexPath", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"increments indexPath for cells after ad row in same section", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:3 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil indexPath", ^{
                [adjuster trueIndexPath:nil] should be_nil;
            });
        });
        
        describe(@"-trueIndexPaths", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                                [NSIndexPath indexPathForRow:1 inSection:0],
                                                [NSIndexPath indexPathForRow:2 inSection:0]];
                
                [adjuster trueIndexPaths:externalIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:2 inSection:0],
                                                                            [NSIndexPath indexPathForRow:3 inSection:0]]);
            });
        });
        
        
        describe(@"-willInsertRowsAtExternalIndexPaths:", ^{
            it(@"leaves adIndexPath unchanged if insertion is after adIndexPath", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"increments adIndexPath if insertions is before adIndexPath", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"increments adIndexPath if insertion is at adIndexPath", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"leaves adIndexPath unchanged for insertion in a different section", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"handles multiple indexPaths inserted and places the ad in the right place", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:0 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:3 inSection:0]);
            });
        });
        
        describe(@"-willDeleteRowsAtExternalIndexPaths:", ^{
            it(@"leaves adIndexPath unchanged if deletion is after adIndexPath", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"decrements adIndexPath if deletion is before adIndexPath", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"leaves adIndexPath unchanged if deletion is at adIndexPath", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"leaves adIndexPath unchanged for deletion in a different section", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"handles multiple indexPaths deleted and places the ad in the right place", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
        });
        
        describe(@"-willMoveRowAtExternalIndexPath:toExternalIndexPath:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            sharedExamplesFor(@"moving a row", ^(NSDictionary *sharedContext) {
                __block NSArray *trueIndexPaths;
                __block NSIndexPath *externalStartIndex;
                __block NSIndexPath *externalFinalIndex;
                __block NSIndexPath *initialAdIndex;
                
                beforeEach(^{
                    externalStartIndex = sharedContext[@"externalStartIndex"];
                    externalFinalIndex = sharedContext[@"externalFinalIndex"];
                    initialAdIndex = multiSectionAdjuster.adIndexPath;
                    multiSectionAdjuster.adLoaded = YES;
                    trueIndexPaths = [multiSectionAdjuster willMoveRowAtExternalIndexPath:externalStartIndex
                                                                      toExternalIndexPath:externalFinalIndex];
                });
                
                it(@"correctly adjusts the ad's index", ^{
                    NSInteger row = [initialAdIndex row] + [sharedContext[@"expectedChangeToAdRow"] integerValue];
                    
                    NSIndexPath *expectedIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
                    multiSectionAdjuster.adIndexPath should equal(expectedIndexPath);
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
                        sharedContext[@"expectedChangeToAdRow"] = @1;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @1;
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @1;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(BEFORE -> AFTER)handles moving from an index path before an ad to an index path that is after an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        sharedContext[@"expectedChangeToAdRow"] = @-1;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                        
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
            });
            
            describe(@"moving from an ad section to a non-ad section", ^{
                describe(@"(BEFORE -> NEW SECTION)moving from before the ad to another section", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        sharedContext[@"expectedChangeToAdRow"] = @-1;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @1;
                        
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
                        sharedContext[@"expectedChangeToFinalRow"] = @1;
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
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            describe(@"when some of the sections around the ad section are being deleted", ^{
                it(@"moves up the ad section by the appropriate amount", ^{
                    multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
                });
            });
            
            describe(@"when one of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:-1 inSection:-1]);
                });
            });
            
            describe(@"when none of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:1];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
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
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:-1 inSection:-1]);
                });
            });
        });
        
        describe(@"-willInsertSections:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            describe(@"when some of the sections around the ad section are being inserting", ^{
                it(@"moves down the ad section by the appropriate amount", ^{
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willInsertSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:3]);
                });
            });
        });
        
        describe(@"-willMoveSection:toSection:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            describe(@"moving a section that is before the ad section", ^{
                describe(@"to still be before the ad section", ^{
                    beforeEach(^{
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
                    });
                    
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:1];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
                    });
                });
                
                describe(@"to be after the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
                    });
                });
            });
            
            describe(@"moving a section that is after the ad section", ^{
                describe(@"to be before the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:0];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:1];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                    
                });
                
                describe(@"to still be after the ad section", ^{
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:3 toSection:2];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
                    });
                });
            });
            
            describe(@"moving the ad section", ^{
                it(@"adjusts the ad section to be the new place", ^{
                    [multiSectionAdjuster willMoveSection:1 toSection:5];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:5]);
                });
            });
        });

    });
    
    describe(@"When an ad is not loaded", ^{
        beforeEach(^{
            adjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            adjuster.adLoaded = NO;
        });
        
        describe(@"-isAdAtIndexPath:", ^{
            it(@"returns NO if indexPaths match", ^{
                [adjuster isAdAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should be_falsy;
            });
        });
        
        describe(@"-externalIndexPath:", ^{
            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"returns the original index path if the index path is equal to adIndexPath", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"returns the original index path for cells after ad row in same section", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster externalIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil index path", ^{
                [adjuster externalIndexPath:nil] should be_nil;
            });
        });
        
        describe(@"-externalIndexPaths", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *trueIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                            [NSIndexPath indexPathForRow:2 inSection:0]];
                
                [adjuster externalIndexPaths:trueIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                                                            [NSIndexPath indexPathForRow:2 inSection:0]]);
                
            });
        });
        
        describe(@"-trueIndexPath:", ^{
            it(@"leaves indexPath unchanged if it's above adIndexPath", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"returns the original indexPath if it's equal to adIndexPath", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"returns the original indexPath for cells after ad row in same section", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]] should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"leaves indexPath unchanged for cells in different section", ^{
                [adjuster trueIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should equal([NSIndexPath indexPathForRow:2 inSection:1]);
            });
            
            it(@"returns nil if passed in a nil indexPath", ^{
                [adjuster trueIndexPath:nil] should be_nil;
            });
        });
        
        describe(@"-trueIndexPaths", ^{
            it(@"adjusts all of the index paths", ^{
                NSArray *externalIndexPaths = @[[NSIndexPath indexPathForRow:0 inSection:0],
                                                [NSIndexPath indexPathForRow:1 inSection:0],
                                                [NSIndexPath indexPathForRow:2 inSection:0]];
                
                [adjuster trueIndexPaths:externalIndexPaths] should equal(@[[NSIndexPath indexPathForRow:0 inSection:0],
                                                                            [NSIndexPath indexPathForRow:1 inSection:0],
                                                                            [NSIndexPath indexPathForRow:2 inSection:0]]);
            });
        });
        
        describe(@"-willInsertRowsAtExternalIndexPaths:", ^{
            it(@"leaves adIndexPath unchanged if insertion is after adIndexPath", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"increments adIndexPath if insertions is before adIndexPath", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"increments adIndexPath if insertion is at adIndexPath", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:2 inSection:0]);
            });
            
            it(@"leaves adIndexPath unchanged for insertion in a different section", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"handles multiple indexPaths inserted and places the ad in the right place", ^{
                [adjuster willInsertRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0], [NSIndexPath indexPathForRow:0 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:3 inSection:0]);
            });
        });
        
        describe(@"-willDeleteRowsAtExternalIndexPaths:", ^{
            it(@"leaves adIndexPath unchanged if deletion is after adIndexPath", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:2 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"decrements adIndexPath if deletion is before adIndexPath", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
            
            it(@"leaves adIndexPath unchanged if deletion is at adIndexPath", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"leaves adIndexPath unchanged for deletion in a different section", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
            });
            
            it(@"handles multiple indexPaths deleted and places the ad in the right place", ^{
                [adjuster willDeleteRowsAtExternalIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0], [NSIndexPath indexPathForRow:1 inSection:0]]];
                adjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
            });
        });
        
        describe(@"-willMoveRowAtExternalIndexPath:toExternalIndexPath:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            sharedExamplesFor(@"moving a row", ^(NSDictionary *sharedContext) {
                __block NSArray *trueIndexPaths;
                __block NSIndexPath *externalStartIndex;
                __block NSIndexPath *externalFinalIndex;
                __block NSIndexPath *initialAdIndex;
                
                beforeEach(^{
                    externalStartIndex = sharedContext[@"externalStartIndex"];
                    externalFinalIndex = sharedContext[@"externalFinalIndex"];
                    initialAdIndex = multiSectionAdjuster.adIndexPath;
                    multiSectionAdjuster.adLoaded = YES;
                    trueIndexPaths = [multiSectionAdjuster willMoveRowAtExternalIndexPath:externalStartIndex
                                                                      toExternalIndexPath:externalFinalIndex];
                });
                
                it(@"correctly adjusts the ad's index", ^{
                    NSInteger row = [initialAdIndex row] + [sharedContext[@"expectedChangeToAdRow"] integerValue];
                    
                    NSIndexPath *expectedIndexPath = [NSIndexPath indexPathForRow:row inSection:0];
                    multiSectionAdjuster.adIndexPath should equal(expectedIndexPath);
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
                        sharedContext[@"expectedChangeToAdRow"] = @1;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @1;
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:2 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @1;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
                
                describe(@"(BEFORE -> AFTER)handles moving from an index path before an ad to an index path that is after an ad", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        sharedContext[@"expectedChangeToAdRow"] = @-1;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
                        sharedContext[@"externalStartIndex"] = [NSIndexPath indexPathForRow:1 inSection:0];
                        sharedContext[@"expectedChangeToStartRow"] = @0;
                        
                        sharedContext[@"externalFinalIndex"] = [NSIndexPath indexPathForRow:0 inSection:0];
                        sharedContext[@"expectedChangeToFinalRow"] = @0;
                        
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
                    });
                    
                    itShouldBehaveLike(@"moving a row");
                });
            });
            
            describe(@"moving from an ad section to a non-ad section", ^{
                describe(@"(BEFORE -> NEW SECTION)moving from before the ad to another section", ^{
                    beforeEach(^{
                        NSMutableDictionary *sharedContext = [[SpecHelper specHelper] sharedExampleContext];
                        sharedContext[@"expectedChangeToAdRow"] = @-1;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @0;
                        
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
                        sharedContext[@"expectedChangeToAdRow"] = @1;
                        
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
                        sharedContext[@"expectedChangeToFinalRow"] = @1;
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
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            describe(@"when some of the sections around the ad section are being deleted", ^{
                it(@"moves up the ad section by the appropriate amount", ^{
                    multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:0 inSection:0]);
                });
            });
            
            describe(@"when one of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:0];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:-1 inSection:-1]);
                });
            });
            
            describe(@"when none of the sections being deleted contains an ad", ^{
                it(@"updates the ad location", ^{
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:1];
                    [multiSectionAdjuster willDeleteSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
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
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:-1 inSection:-1]);
                });
            });
        });
        
        describe(@"-willInsertSections:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            describe(@"when some of the sections around the ad section are being inserting", ^{
                it(@"moves down the ad section by the appropriate amount", ^{
                    NSMutableIndexSet *indices = [NSMutableIndexSet indexSet];
                    [indices addIndex:0];
                    [indices addIndex:1];
                    [indices addIndex:3];
                    
                    [multiSectionAdjuster willInsertSections:indices];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:3]);
                });
            });
        });
        
        describe(@"-willMoveSection:toSection:", ^{
            __block STRAdPlacementAdjuster *multiSectionAdjuster;
            
            beforeEach(^{
                multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
            });
            
            describe(@"moving a section that is before the ad section", ^{
                describe(@"to still be before the ad section", ^{
                    beforeEach(^{
                        multiSectionAdjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:5 articlesBetweenAds:5];
                    });
                    
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:1];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
                    });
                });
                
                describe(@"to be after the ad section", ^{
                    it(@"adjusts the ad section up", ^{
                        [multiSectionAdjuster willMoveSection:0 toSection:2];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:0]);
                    });
                });
            });
            
            describe(@"moving a section that is after the ad section", ^{
                describe(@"to be before the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:0];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                });
                
                describe(@"to the ad section", ^{
                    it(@"adjusts the ad section down", ^{
                        [multiSectionAdjuster willMoveSection:2 toSection:1];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:2]);
                    });
                    
                });
                
                describe(@"to still be after the ad section", ^{
                    it(@"does not adjust the ad placement", ^{
                        [multiSectionAdjuster willMoveSection:3 toSection:2];
                        multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:1]);
                    });
                });
            });
            
            describe(@"moving the ad section", ^{
                it(@"adjusts the ad section to be the new place", ^{
                    [multiSectionAdjuster willMoveSection:1 toSection:5];
                    multiSectionAdjuster.adIndexPath should equal([NSIndexPath indexPathForRow:1 inSection:5]);
                });
            });
        });
    });
});
*/
SPEC_END
