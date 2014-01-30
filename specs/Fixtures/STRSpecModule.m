#import "STRSpecModule.h"

@implementation SpecModule

- (void)configureWithInjector:(STRInjector *)injector {
    [injector bind:@"specKey" toInstance:@"specKeyInstance"];
}

@end
