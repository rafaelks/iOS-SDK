#import "STRTableViewAdGenerator.h"
#import "SharethroughSDK.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewDataSource.h"
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRTableViewCell.h"
#import "STRAdGenerator.h"
#import <objc/runtime.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const kTableViewAdGeneratorKey;

SPEC_BEGIN(STRTableViewAdGeneratorSpec)

describe(@"STRTableViewAdGenerator", ^{
    __block STRTableViewAdGenerator *tableViewAdGenerator;
    __block STRAdGenerator *adGenerator;
    __block UITableView *tableView;
    __block UIViewController *presentingViewController;

    beforeEach(^{
        STRInjector *injector = [STRInjector injectorForModule:[STRAppModule new]];

        adGenerator = nice_fake_for([STRAdGenerator class]);
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        tableViewAdGenerator = [injector getInstance:[STRTableViewAdGenerator class]];

        presentingViewController = [UIViewController new];
        tableView = [UITableView new];
        tableView.frame = CGRectMake(0, 0, 100, 400);
    });

    describe(@"placing an ad in the table view", ^{
        beforeEach(^{
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
        });

        it(@"stores itself as an associated object of the table view", ^{
            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
            [tableView layoutIfNeeded];

            objc_getAssociatedObject(tableView, kTableViewAdGeneratorKey) should be_same_instance_as(tableViewAdGenerator);
        });

        describe(@"when the data source only implements required methods", ^{
            __block STRTableViewDataSource<UITableViewDataSource> *dataSource;

            beforeEach(^{
                dataSource = [STRTableViewDataSource new];
                dataSource.rowsInEachSection = 2;
                tableView.dataSource = dataSource;

                [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
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

                adGenerator should have_received(@selector(placeAdInView:placementKey:presentingViewController:)).with(adCell, @"placementKey", presentingViewController);

                contentCell = tableView.visibleCells[2];
                contentCell.textLabel.text should equal(@"row: 1, section: 0");
            });
        });

        describe(@"when the data source implements all methods", ^{
            __block STRFullTableViewDataSource<UITableViewDataSource> *dataSource;

            beforeEach(^{
                dataSource = [STRFullTableViewDataSource new];
                tableView.dataSource = dataSource;
            });

            describe(@"and the original data source reports there is more than one section", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 2;
                    dataSource.rowsInEachSection = 1;

                    [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
                    [tableView layoutIfNeeded];
                });

                it(@"only inserts a row in the first section", ^{
                    [tableView numberOfRowsInSection:0] should equal(2);
                    [tableView numberOfRowsInSection:1] should equal(1);
                });
            });

            describe(@"if the original data source reports that there are no sections in the table view", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 0;
                    dataSource.rowsInEachSection = 0;

                    [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
                    [tableView layoutIfNeeded];
                });

                it(@"creates a first section and then puts the ad in it", ^{
                    [tableView numberOfSections] should equal(1);
                    [tableView numberOfRowsInSection:0] should equal(1);

                    STRTableViewCell *adCell = (STRTableViewCell *) tableView.visibleCells[0];
                    adCell should be_instance_of([STRTableViewCell class]);
                });
            });

            it(@"forwards other selectors to the data source", ^{
                [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
                [tableView layoutIfNeeded];

                [tableView footerViewForSection:0].textLabel.text should equal(@"title for footer");
            });
        });
    });

    describe(@"placing an ad in the table view when the reuse identifier was badly registered", ^{
        __block STRTableViewDataSource *dataSource;

        beforeEach(^{
            dataSource = [STRTableViewDataSource new];
            tableView.dataSource = dataSource;

            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController];
        });

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
});

SPEC_END
