#import "STRPromise.h"

@interface STRDeferred : NSObject

@property (strong, nonatomic) STRPromise *promise;

+ (instancetype)defer;

- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;

@end