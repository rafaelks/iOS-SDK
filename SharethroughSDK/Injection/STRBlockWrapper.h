#import <Foundation/Foundation.h>
#import "STRInjector.h"

@interface STRBlockWrapper : NSObject

@property (nonatomic, strong) STRInjectorBlock injectorBlock;

+ (instancetype)wrapperWithBlock:(STRInjectorBlock)injectorBlock;

- (id)valueWithInjector:(STRInjector *)injector;

@end
