#import "STRInjector.h"
#import "STRBlockWrapper.h"
#import "STRSingletonBlockWrapper.h"
#import "STRAppModule.h"

@interface STRInjector ()

@property (nonatomic, strong) NSMutableDictionary *bindings;

@end

@implementation STRInjector

+ (instancetype)injectorForModule:(id<STRInjectorModule>)module {
    STRInjector *injector = [self new];
    [module configureWithInjector:injector];
    return injector;
}

- (id)init {
    self = [super init];
    if (self) {
        self.bindings = [NSMutableDictionary dictionary];
    }

    return self;
}

- (void)bind:(id)key toInstance:(id)instance {
    self.bindings[key] = instance;
}

- (void)bind:(id)key toBlock:(STRInjectorBlock)block {
    self.bindings[key] = [STRBlockWrapper wrapperWithBlock:block];
}

- (void)bind:(id)key toBlockAsSingleton:(STRInjectorBlock)block {
    self.bindings[key] = [STRSingletonBlockWrapper wrapperWithBlock:block];
}

- (id)getInstance:(id)key {
    id val = self.bindings[key];

    if (!val) {
        [NSException raise:@"Injector" format:@"Injector does not have a value bound for key: %@", key];
    }

    if ([val isKindOfClass:[STRSingletonBlockWrapper class]]) {
        id blockResult = [(STRBlockWrapper *)val valueWithInjector:self];
        self.bindings[key] = blockResult;
        return blockResult;
    } else if ([val isKindOfClass:[STRBlockWrapper class]]) {
        return [(STRBlockWrapper *)val valueWithInjector:self];
    }

    return val;
}

@end
