//
//  KKDescribable.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/16.
//

#import "KKDescribable.h"
#import <objc/runtime.h>

@implementation KKDescribable

- (NSString *)description
{
    NSMutableString* desc = [NSMutableString string];
    [desc appendString:@"{"];
    
    unsigned int count;
    Ivar* ivars = class_copyIvarList(self.class, &count);
    for (unsigned int i = 0; i < count; ++i) {
        if (desc.length) [desc appendString:@"\r        "];
        
        const char* name = ivar_getName(ivars[i]);
        const char* encoding = ivar_getTypeEncoding(ivars[i]);
        
        ptrdiff_t offset = ivar_getOffset(ivars[i]);
        void **location = (void**)((__bridge void *)self + offset);
        
        /* raw pointer not support valueForKey */
        if (strstr(encoding, "^")) {
            [desc appendFormat:@"%s:%p", name, *location];
        } else if (strstr(encoding, "@")) {
            [desc appendFormat:@"%s:%@", name, (__bridge id)(*location)];
        } else{
            NSString* property = [NSString stringWithFormat:@"%s", name];
            [desc appendFormat:@"%s:%@", name, [self valueForKey:property]];
        }
    }
    free(ivars);
    [desc appendString:@"\r    }"];
    return desc;
}
@end
