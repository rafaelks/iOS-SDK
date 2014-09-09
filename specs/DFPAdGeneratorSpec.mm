#import "STRSpecModule.h"
#import <objc/runtime.h>

#import "STRDFPAdGenerator.h"
#import "STRInjector.h"
#import "STRAdService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(STRDFPAdGeneratorSpec)

describe(@"Injector", ^{
    __block STRDFPAdGenerator *generator;
    __block STRAdService *adService;
    __block STRInjector *injector;

    beforeEach(^{
        injector = [STRInjector new];
        
        adService = nice_fake_for([STRAdService class]);
        [injector bind:[STRAdService class] toInstance:adService];
        
        generator = [injector getInstance:[STRDFPAdGenerator class]];
    });

    describe(@"when configuring an injector from a module", ^{
        beforeEach(^{
            id<STRInjectorModule> module = [SpecModule new];
            injector = [STRInjector injectorForModule:module];
        });

        it(@"has the bindings from the module available", ^{
            [injector getInstance:@"specKey"] should equal(@"specKeyInstance");
        });
    });

});

SPEC_END
