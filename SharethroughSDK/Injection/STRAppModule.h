#import <Foundation/Foundation.h>
#import "STRInjector.h"

@interface STRAppModule : NSObject<STRInjectorModule>

+ (instancetype)moduleWithStaging:(BOOL)staging;

@end
