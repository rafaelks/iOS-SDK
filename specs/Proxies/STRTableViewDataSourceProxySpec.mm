#import "STRGridlikeViewDataSourceProxy.h"
#import "STRAdPlacementAdjuster.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRFakeAdGenerator.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewCell.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRTableViewDataSourceProxySpec)

describe(@"STRGridlikeViewDataSourceProxy UITableViewDataSource", ^{
    __block STRGridlikeViewDataSourceProxy *proxy;
    __block STRAdGenerator *adGenerator;
    __block UITableView *tableView;
    __block UIViewController *presentingViewController;
    __block STRInjector *injector;
    __block id<UITableViewDataSource> originalDataSource;
    
    STRGridlikeViewDataSourceProxy *(^proxyWithDataSource)(id<UITableViewDataSource> dataSource) = ^STRGridlikeViewDataSourceProxy *(id<UITableViewDataSource> dataSource) {
        
        STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterInSection:0 articlesBeforeFirstAd:1 articlesBetweenAds:100];

        STRGridlikeViewDataSourceProxy *dataSourceProxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController injector:injector];
        dataSourceProxy.originalDataSource = dataSource;
        dataSourceProxy.adjuster = adjuster;
        return dataSourceProxy;
    };
    
    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];
        
        adGenerator = [STRFakeAdGenerator new];
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];
        
        presentingViewController = [UIViewController new];
        
        originalDataSource = [STRFullTableViewDataSource new];
        proxy = proxyWithDataSource(originalDataSource);
        
        tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 100, 400)];
        tableView.dataSource = proxy;
    });
    
    it(@"forwards other selectors to the data source", ^{
        [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
        [tableView layoutIfNeeded];
        
        [tableView footerViewForSection:0].textLabel.text should equal(@"title for footer");
    });
    
    describe(@"when the data source only implements required methods", ^{
        __block STRTableViewDataSource *dataSource;
        
        beforeEach(^{
            dataSource = [STRTableViewDataSource new];
            dataSource.rowsForEachSection = @[@2];
            
            proxy = proxyWithDataSource(dataSource);
            
            tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 100, 400)];
            tableView.dataSource = proxy;
            
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
            
            [tableView layoutIfNeeded];
        });
        
        describe(@"when an ad is loaded", ^{
            beforeEach(^{
                [proxy prefetchAdForGridLikeView:tableView atIndex:1];
            });
            
            it(@"inserts an extra row in the first section", ^{
                [tableView numberOfSections] should equal(1);
                [tableView numberOfRowsInSection:0] should equal(3);
            });
            
            it(@"inserts an ad into the second row of the first section", ^{
                UITableViewCell *contentCell = tableView.visibleCells[0];
                contentCell.textLabel.text should equal(@"row: 0, section: 0");
                
                STRTableViewCell *adCell = (STRTableViewCell *) tableView.visibleCells[1];
                adCell should be_instance_of([STRTableViewCell class]);
                
                contentCell = tableView.visibleCells[2];
                contentCell.textLabel.text should equal(@"row: 1, section: 0");
            });
        });
        
        describe(@"when an ad is not loaded", ^{
            it(@"does not insert an extra row in the first section", ^{
                [tableView numberOfSections] should equal(1);
                [tableView numberOfRowsInSection:0] should equal(2);
            });
        });
    });
    
    describe(@"when the original data source implements all methods", ^{
        __block STRFullTableViewDataSource *dataSource;
        
        beforeEach(^{
            dataSource = [STRFullTableViewDataSource new];
            dataSource.numberOfSections = 2;
            dataSource.rowsForEachSection = @[@1, @1];
            
            proxy = proxyWithDataSource(dataSource);
            tableView.dataSource = proxy;
        });
        
        describe(@"and the original data source reports there is more than one section", ^{
            beforeEach(^{
                [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
                [proxy prefetchAdForGridLikeView:tableView atIndex:1];
                [tableView layoutIfNeeded];
            });
            
            
            it(@"only inserts an ad in the first section", ^{
                [tableView numberOfRowsInSection:0] should equal(2);
                [tableView numberOfRowsInSection:1] should equal(1);
            });
        });
    });
    
    describe(@"placing an ad in the table view when the reuse identifier was badly registered", ^{
        it(@"throws an exception if the sdk user does not register the identifier", ^{
            expect(^{
                [proxy prefetchAdForGridLikeView:tableView atIndex:1];
                [tableView layoutIfNeeded];
            }).to(raise_exception());
        });
        
        it(@"throws an exception if the sdk user registers a cell that doesn't conform to STRAdView", ^{
            [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"adCell"];
            
            expect(^{
                [proxy prefetchAdForGridLikeView:tableView atIndex:1];
                [tableView layoutIfNeeded];
            }).to(raise_exception());
        });
    });
});

SPEC_END
