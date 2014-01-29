#import <Foundation/Foundation.h>

@class STRInjector;
@protocol STRInjectorModule;

typedef id(^STRInjectorBlock)(STRInjector *injector);

@interface STRInjector : NSObject

+ (instancetype)injectorForModule:(id<STRInjectorModule>)injectorModule;

- (void)bind:(id)key toInstance:(id)instance;
- (void)bind:(id)key toBlock:(STRInjectorBlock)block;
- (void)bind:(id)key toBlockAsSingleton:(STRInjectorBlock)block;

- (id)getInstance:(id)key;

@end

@protocol STRInjectorModule <NSObject>

- (void)configureWithInjector:(STRInjector *)injector;

@end
