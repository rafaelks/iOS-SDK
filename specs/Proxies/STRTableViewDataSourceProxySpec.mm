#import "STRTableViewDataSourceProxy.h"
#import "STRAdPlacementAdjuster.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewCell.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRTableViewDataSourceProxySpec)

describe(@"STRTableViewDataSourceProxy", ^{
    __block STRTableViewDataSourceProxy *proxy;
    __block STRAdGenerator *adGenerator;
    __block UITableView *tableView;
    __block UIViewController *presentingViewController;
    __block STRInjector *injector;
    __block id<UITableViewDataSource> originalDataSource;

    STRTableViewDataSourceProxy *(^proxyWithDataSource)(id<UITableViewDataSource> dataSource) = ^STRTableViewDataSourceProxy *(id<UITableViewDataSource> dataSource) {

        STRAdPlacementAdjuster *adjuster = [STRAdPlacementAdjuster adjusterWithInitialAdIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

        return [[STRTableViewDataSourceProxy alloc] initWithOriginalDataSource:dataSource adjuster:adjuster adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController injector:injector];
    };

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        adGenerator = nice_fake_for([STRAdGenerator class]);
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

        it(@"inserts an extra row in the first section", ^{
            [tableView numberOfSections] should equal(1);
            [tableView numberOfRowsInSection:0] should equal(3);
        });

        it(@"inserts an ad into the second row of the first section", ^{
            UITableViewCell *contentCell = tableView.visibleCells[0];
            contentCell.textLabel.text should equal(@"row: 0, section: 0");

            STRTableViewCell *adCell = (STRTableViewCell *) tableView.visibleCells[1];
            adCell should be_instance_of([STRTableViewCell class]);

            adGenerator should have_received(@selector(placeAdInView:placementKey:presentingViewController:delegate:)).with(adCell, @"placementKey", presentingViewController, nil);

            contentCell = tableView.visibleCells[2];
            contentCell.textLabel.text should equal(@"row: 1, section: 0");
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
                [tableView layoutIfNeeded];
            });

            
            it(@"only inserts a row in the first section", ^{
                [tableView numberOfRowsInSection:0] should equal(2);
                [tableView numberOfRowsInSection:1] should equal(1);
            });
        });
    });

    describe(@"placing an ad in the table view when the reuse identifier was badly registered", ^{

        it(@"throws an exception if the sdk user does not register the identifier", ^{
            expect(^{
                [tableView layoutIfNeeded];
            }).to(raise_exception());
        });

        it(@"throws an exception if the sdk user registers a cell that doesn't conform to STRAdView", ^{
            [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"adCell"];

            expect(^{
                [tableView layoutIfNeeded];
            }).to(raise_exception());
        });
    });

    describe(@"-proxyWithNewDataSource:", ^{
        it(@"returns a new proxy with a different data source", ^{
            id <UITableViewDataSource> newDataSource = nice_fake_for(@protocol(UITableViewDataSource));

            STRTableViewDataSourceProxy *newProxy = [proxy proxyWithNewDataSource:newDataSource];
            newProxy should_not be_same_instance_as(proxy);
            newProxy.originalDataSource should be_same_instance_as(newDataSource);
            newProxy.adCellReuseIdentifier should equal(@"adCell");
            newProxy.placementKey should equal(@"placementKey");
            newProxy.presentingViewController should be_same_instance_as(presentingViewController);
            newProxy.injector should be_same_instance_as(injector);
        });
    });
});

SPEC_END
