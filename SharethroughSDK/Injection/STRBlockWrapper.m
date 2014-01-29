#import "STRBlockWrapper.h"

@implementation STRBlockWrapper

+ (instancetype)wrapperWithBlock:(STRInjectorBlock)injectorBlock {
    STRBlockWrapper *blockWrapper = [self new];
    blockWrapper.injectorBlock = injectorBlock;
    return blockWrapper;
}

- (id)valueWithInjector:(STRInjector *)injector {
    return self.injectorBlock(injector);
}


@end
