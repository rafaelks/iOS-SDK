#import "STRSpecModuleFixture.h"

@implementation SpecModuleFixture

- (void)configureWithInjector:(STRInjector *)injector {
    [injector bind:@"specKey" toInstance:@"specKeyInstance"];
}

@end
