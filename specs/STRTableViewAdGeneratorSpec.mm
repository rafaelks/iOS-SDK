#import "STRTableViewAdGenerator.h"
#import "SharethroughSDK.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewDataSource.h"
#import "STRTableViewCell.h"
#import "STRTableViewDelegateProxy.h"
#import "STRTableViewDelegate.h"
#import "STRFullTableViewDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const STRTableViewAdGeneratorKey;

SPEC_BEGIN(STRTableViewAdGeneratorSpec)

describe(@"STRTableViewAdGenerator", ^{
    __block STRTableViewAdGenerator *tableViewAdGenerator;
    __block STRAdGenerator *adGenerator;
    __block UITableView *tableView;
    __block UIViewController *presentingViewController;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        adGenerator = nice_fake_for([STRAdGenerator class]);
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        tableViewAdGenerator = [injector getInstance:[STRTableViewAdGenerator class]];

        presentingViewController = [UIViewController new];
        tableView = [UITableView new];
        tableView.frame = CGRectMake(0, 0, 100, 400);
    });

    describe(@"wiring up tableview delegate", ^{
        __block STRTableViewDelegate *tableViewController;

        beforeEach(^{
            tableViewController = [STRTableViewDelegate new];

            tableView.delegate = tableViewController;
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];

            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:nil ];
            [tableView layoutIfNeeded];
        });

        it(@"tableview's delegate points to a proxy", ^{
            id<UITableViewDelegate> delegate = tableView.delegate;

            [delegate isKindOfClass:[STRTableViewDelegateProxy class]] should be_truthy;
        });

        it(@"proxy points to tableview's original delegate", ^{
            STRTableViewDelegateProxy *proxy = tableView.delegate;
            proxy.originalDelegate should be_same_instance_as(tableViewController);
        });
    });



    describe(@"placing an ad in the table view", ^{
        beforeEach(^{
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
        });

        it(@"stores itself as an associated object of the table view", ^{
            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:nil ];
            [tableView layoutIfNeeded];

            objc_getAssociatedObject(tableView, STRTableViewAdGeneratorKey) should be_same_instance_as(tableViewAdGenerator);
        });

        describe(@"when the data source only implements required methods", ^{
            __block STRTableViewDataSource<UITableViewDataSource> *dataSource;

            beforeEach(^{
                dataSource = [STRTableViewDataSource new];
                dataSource.rowsForEachSection = @[@2];
                tableView.dataSource = dataSource;

                [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:nil ];
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

        describe(@"when the data source implements all methods", ^{
            __block STRFullTableViewDataSource<UITableViewDataSource> *dataSource;

            beforeEach(^{
                dataSource = [STRFullTableViewDataSource new];
                tableView.dataSource = dataSource;
            });

            describe(@"and the original data source reports there is more than one section", ^{
                beforeEach(^{
                    dataSource.numberOfSections = 2;
                    dataSource.rowsForEachSection = @[@1, @1];

                    [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:nil ];
                    [tableView layoutIfNeeded];
                });

                it(@"only inserts a row in the first section", ^{
                    [tableView numberOfRowsInSection:0] should equal(2);
                    [tableView numberOfRowsInSection:1] should equal(1);
                });
            });

            it(@"forwards other selectors to the data source", ^{
                [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:nil ];
                [tableView layoutIfNeeded];

                [tableView footerViewForSection:0].textLabel.text should equal(@"title for footer");
            });
        });
    });

    describe(@"placing ad with a custom index path", ^{
        __block STRFullTableViewDataSource *dataSource;

        beforeEach(^{
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];

            dataSource = [STRFullTableViewDataSource new];
            tableView.dataSource = dataSource;
            dataSource.rowsForEachSection = @[@0, @2];
        });

        it(@"puts the ad there", ^{
            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
            [tableView numberOfRowsInSection:1] should equal(3);
            [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]] should be_instance_of([STRTableViewCell class]);
        });

        context(@"and the index path is out of bounds", ^{
            it(@"raises an exception", ^{
                expect(^{
                    [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
                }).to(raise_exception());
            });
        });

        context(@"and then index path would be valid when the ad is inserted", ^{
            it(@"is still able to place the ad there", ^{
                [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]];
                [tableView numberOfRowsInSection:1] should equal(3);
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]] should be_instance_of([STRTableViewCell class]);
            });
        });
    });

    describe(@"place an ad in the table view twice", ^{
        __block STRFullTableViewDataSource *dataSource;
        __block id<UITableViewDelegate, CedarDouble> delegate;

        beforeEach(^{
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];

            dataSource = [STRFullTableViewDataSource new];
            tableView.dataSource = dataSource;
            dataSource.rowsForEachSection = @[@2, @2];

            delegate = nice_fake_for(@protocol(UITableViewDelegate));
            delegate reject_method(@selector(tableView:accessoryTypeForRowWithIndexPath:));
            tableView.delegate = delegate;

            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

            [tableView numberOfRowsInSection:0] should equal(3);
            [tableView numberOfRowsInSection:1] should equal(2);
        });

        it(@"reloads the data to remove the previously placed ad", ^{
            STRTableViewAdGenerator *newTableAdGenerator = [injector getInstance:[STRTableViewAdGenerator class]];
            [newTableAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

            [tableView numberOfRowsInSection:0] should equal(2);
            [tableView numberOfRowsInSection:1] should equal(3);
        });

        it(@"points delegate proxy to original delegate", ^{
            STRTableViewAdGenerator *newTableAdGenerator = [injector getInstance:[STRTableViewAdGenerator class]];
            [newTableAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

            [tableView.delegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

            __autoreleasing NSIndexPath *indexPath;
            [[delegate.sent_messages lastObject] getArgument:&indexPath atIndex:3];

            delegate should have_received(@selector(tableView:didSelectRowAtIndexPath:))
            .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
        });
    });

    describe(@"placing an ad in the table view when the reuse identifier was badly registered", ^{
        __block STRTableViewDataSource *dataSource;

        beforeEach(^{
            dataSource = [STRTableViewDataSource new];
            tableView.dataSource = dataSource;

            [tableViewAdGenerator placeAdInTableView:tableView adCellReuseIdentifier:@"adCell" placementKey:@"placementKey" presentingViewController:presentingViewController adHeight:10 adStartingIndexPath:nil ];
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
