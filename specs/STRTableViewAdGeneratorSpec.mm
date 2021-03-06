#import "STRGridlikeViewAdGenerator.h"
#import "SharethroughSDK.h"
#import <objc/runtime.h>
#import "STRInjector.h"
#import "STRAppModule.h"
#import "STRAdGenerator.h"
#import "STRFakeAdGenerator.h"
#import "STRFullTableViewDataSource.h"
#import "STRTableViewDataSource.h"
#import "STRTableViewCell.h"
#import "STRIndexPathDelegateProxy.h"
#import "STRTableViewDelegate.h"
#import "STRFullTableViewDelegate.h"
#import "STRGridlikeViewDataSourceProxy.h"
#import "STRAdCache.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

extern const char *const STRGridlikeViewAdGeneratorKey;

SPEC_BEGIN(STRTableViewAdGeneratorSpec)

describe(@"STRGridlikeViewAdGenerator UITableView", ^{
    __block STRGridlikeViewAdGenerator *tableViewAdGenerator;
    __block STRAdGenerator *adGenerator;
    __block UITableView *tableView;
    __block UIViewController *presentingViewController;
    __block STRInjector *injector;
    __block STRGridlikeViewDataSourceProxy *dataSourceProxy;
    __block STRAdCache *fakeAdCache;

    beforeEach(^{
        injector = [STRInjector injectorForModule:[STRAppModule new]];

        fakeAdCache = nice_fake_for([STRAdCache class]);
        fakeAdCache stub_method(@selector(numberOfAdsAssignedAndNumberOfAdsReadyInQueueForPlacementKey:)).and_return((long)1);
        [injector bind:[STRAdCache class] toInstance:fakeAdCache];

        adGenerator = [STRFakeAdGenerator new];
        [injector bind:[STRAdGenerator class] toInstance:adGenerator];

        tableViewAdGenerator = [injector getInstance:[STRGridlikeViewAdGenerator class]];

        presentingViewController = [UIViewController new];
        tableView = [UITableView new];
        tableView.frame = CGRectMake(0, 0, 100, 400);
        
        dataSourceProxy = [[STRGridlikeViewDataSourceProxy alloc] initWithAdCellReuseIdentifier:@"adCell"
                                                                                      adPlacement:nil
                                                                                       injector:injector];
    });

    describe(@"taking over the table view delegate", ^{
        __block STRTableViewDelegate *tableViewController;

        beforeEach(^{
            tableViewController = [STRTableViewDelegate new];

            tableView.delegate = tableViewController;
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
            
            [tableViewAdGenerator placeAdInGridlikeView:tableView
                                        dataSourceProxy:dataSourceProxy
                                  adCellReuseIdentifier:@"adCell"
                                           placementKey:@"placementKey"
                               presentingViewController:presentingViewController
                                                 adSize:CGSizeZero
                                              adSection:0];

            [tableView layoutIfNeeded];
        });

        it(@"points the table view's delegate to a delegateProxy", ^{
            id<UITableViewDelegate> delegate = tableView.delegate;
            delegate should be_instance_of([STRIndexPathDelegateProxy class]);
        });


        it(@"delegateProxy points to tableview's original delegate", ^{
            STRIndexPathDelegateProxy *proxy = (id)tableView.delegate;
            proxy.originalDelegate should be_same_instance_as(tableViewController);
        });

        it(@"provides an accessor to the original delegate", ^{
            tableViewAdGenerator.originalDelegate should be_same_instance_as(tableViewController);
        });

        it(@"provides a setter to modify the original delegate", ^{
            STRTableViewDelegate *newDelegate = [STRTableViewDelegate new];
            STRIndexPathDelegateProxy *proxy = (STRIndexPathDelegateProxy *)tableView.delegate;
            [tableViewAdGenerator setOriginalDelegate:newDelegate gridlikeView:tableView];

            tableViewAdGenerator.originalDelegate should be_same_instance_as(newDelegate);
            tableView.delegate should_not be_same_instance_as(proxy);
            tableView.delegate should be_instance_of([STRIndexPathDelegateProxy class]);
        });
    });

    describe(@"taking over the table view data source", ^{
        __block STRTableViewDataSource *dataSource;

        beforeEach(^{
            dataSource = [STRTableViewDataSource new];

            tableView.dataSource = dataSource;
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
            
            [tableViewAdGenerator placeAdInGridlikeView:tableView
                                        dataSourceProxy:dataSourceProxy
                                  adCellReuseIdentifier:@"adCell"
                                           placementKey:@"placementKey"
                               presentingViewController:presentingViewController
                                                 adSize:CGSizeZero
                                              adSection:0];
            [tableView layoutIfNeeded];
        });

        it(@"points the table view's data source to a delegateProxy", ^{
            id<UITableViewDataSource> dataSource = tableView.dataSource;
            dataSource should be_instance_of([STRGridlikeViewDataSourceProxy class]);
        });

        it(@"points the delegateProxy's data source to the table view's original data source", ^{
            STRGridlikeViewDataSourceProxy *proxy = (STRGridlikeViewDataSourceProxy *)tableView.dataSource;
            proxy.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"provides an accessor to the original data source", ^{
            tableViewAdGenerator.originalDataSource should be_same_instance_as(dataSource);
        });

        it(@"provides a setter to modify the original data source", ^{
            STRTableViewDataSource *newDataSource = [STRTableViewDataSource new];
            STRGridlikeViewDataSourceProxy *proxy = (STRGridlikeViewDataSourceProxy *)tableView.dataSource;
            [tableViewAdGenerator setOriginalDataSource:newDataSource gridlikeView:tableView];

            tableViewAdGenerator.originalDataSource should be_same_instance_as(newDataSource);
            tableView.dataSource should_not be_same_instance_as(proxy);
            tableView.dataSource should be_instance_of([STRGridlikeViewDataSourceProxy class]);
        });
    });

    describe(@"placing an ad in the table view", ^{
        beforeEach(^{
            [tableView registerClass:[STRTableViewCell class] forCellReuseIdentifier:@"adCell"];
        });

        it(@"stores itself as an associated object of the table view", ^{
            [tableViewAdGenerator placeAdInGridlikeView:tableView
                                        dataSourceProxy:dataSourceProxy
                                  adCellReuseIdentifier:@"adCell"
                                           placementKey:@"placementKey"
                               presentingViewController:presentingViewController
                                                 adSize:CGSizeZero
                                              adSection:0];
            [tableView layoutIfNeeded];

            objc_getAssociatedObject(tableView, STRGridlikeViewAdGeneratorKey) should be_same_instance_as(tableViewAdGenerator);
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
            
            [tableViewAdGenerator placeAdInGridlikeView:tableView
                                        dataSourceProxy:dataSourceProxy
                                  adCellReuseIdentifier:@"adCell"
                                           placementKey:@"placementKey"
                               presentingViewController:presentingViewController
                                                 adSize:CGSizeZero
                                              adSection:0];

            [tableView numberOfRowsInSection:0] should equal(3);
            [tableView numberOfRowsInSection:1] should equal(2);
        });

        it(@"reloads the data to remove the previously placed ad", ^{
            STRGridlikeViewAdGenerator *newTableAdGenerator = [injector getInstance:[STRGridlikeViewAdGenerator class]];
            
            [newTableAdGenerator placeAdInGridlikeView:tableView
                                        dataSourceProxy:dataSourceProxy
                                  adCellReuseIdentifier:@"adCell"
                                           placementKey:@"placementKey"
                               presentingViewController:presentingViewController
                                                 adSize:CGSizeZero
                                             adSection:0];
            [tableView numberOfRowsInSection:0] should equal(3);
            [tableView numberOfRowsInSection:1] should equal(2);
        });

        it(@"points delegate delegateProxy to original delegate", ^{
            STRGridlikeViewAdGenerator *newTableAdGenerator = [injector getInstance:[STRGridlikeViewAdGenerator class]];
            [newTableAdGenerator placeAdInGridlikeView:tableView
                                       dataSourceProxy:dataSourceProxy
                                 adCellReuseIdentifier:@"adCell"
                                          placementKey:@"placementKey"
                              presentingViewController:presentingViewController
                                                adSize:CGSizeZero
                                             adSection:0];
            [tableView.delegate tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];

            __autoreleasing NSIndexPath *indexPath;
            [[delegate.sent_messages lastObject] getArgument:&indexPath atIndex:3];

            delegate should have_received(@selector(tableView:didSelectRowAtIndexPath:))
            .with(tableView, [NSIndexPath indexPathForRow:1 inSection:0]);
        });
    });
});

SPEC_END
