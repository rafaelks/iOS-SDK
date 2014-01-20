#import <Foundation/Foundation.h>

@class STRPromise;

typedef id(^promiseValueCallback)(id value);
typedef id(^promiseErrorCallback)(NSError *error);
typedef void(^deferredCallback)(STRPromise *p);

@interface STRPromise : NSObject
@property (strong, nonatomic, readonly) id value;
@property (strong, nonatomic, readonly) NSError *error;
@property (assign, nonatomic, readonly) BOOL fulfilled;
@property (assign, nonatomic, readonly) BOOL rejected;
@property (assign, nonatomic, readonly) BOOL cancelled;


+ (STRPromise *)when:(NSArray *)promises;
- (STRPromise *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback;
- (void)cancel;

- (id)waitForValue;
- (id)waitForValueWithTimeout:(NSTimeInterval)timeout;

#pragma deprecated
+ (STRPromise *)join:(NSArray *)promises;
- (void)whenResolved:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenRejected:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenFulfilled:(deferredCallback)complete DEPRECATED_ATTRIBUTE;


@end