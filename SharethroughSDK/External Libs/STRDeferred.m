#import "STRDeferred.h"

@interface STRPromise (Deferred)
- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;
@end

@implementation STRDeferred

@synthesize promise = _promise;

+ (instancetype)defer {
    return [[self alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
        self.promise = [[STRPromise alloc] init];
    }
    return self;
}

- (void)resolveWithValue:(id)value {
    [self.promise resolveWithValue:value];
}

- (void)rejectWithError:(NSError *)error {
    [self.promise rejectWithError:error];
}

- (void)fullfillWithValue:(id)value {
}

@end