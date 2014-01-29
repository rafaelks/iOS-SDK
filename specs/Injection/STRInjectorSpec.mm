#import "STRInjector.h"
#import "STRSpecModuleFixture.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRInjectorSpec)

describe(@"Injector", ^{
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector new];
    });

    describe(@"when configuring an injector from a module", ^{
        beforeEach(^{
            id<STRInjectorModule> module = [SpecModuleFixture new];
            injector = [STRInjector injectorForModule:module];
        });

        it(@"has the bindings from the module available", ^{
            [injector getInstance:@"specKey"] should equal(@"specKeyInstance");
        });
    });

    describe(@"when binding through a block", ^{
        it(@"evaluates the block to return the instance", ^{
            [injector bind:@"block" toBlock:^id(STRInjector *injector) {
                return @"blockInstance";
            }];

            [injector getInstance:@"block"] should equal(@"blockInstance");
        });

        it(@"passes in the injector to the block as an argument (for nested injection)", ^{
            __block STRInjector *injectorPassedToBlock;
            [injector bind:@"block" toBlock:^id(STRInjector *injector) {
                injectorPassedToBlock = injector;
                return nil;
            }];

            [injector getInstance:@"block"];
            injectorPassedToBlock should be_same_instance_as(injector);
        });
    });

    describe(@"if the lookup key doesn't exist", ^{
        it(@"raises an exception", ^{
            expect(^{ [injector getInstance:@"non-existent key"]; }).to(raise_exception());
        });
    });

    describe(@"overriding the key with another value", ^{
        it(@"returns the later value", ^{
            [injector bind:@"key" toInstance:@"first val"];
            [injector bind:@"key" toInstance:@"second val"];

            [injector getInstance:@"key"] should equal(@"second val");
        });
    });
});

SPEC_END
