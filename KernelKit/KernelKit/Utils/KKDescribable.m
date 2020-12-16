//
//  KKDescribable.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/16.
//

#import "KKDescribable.h"
#import <objc/runtime.h>

@implementation KKDescribable
static NSMutableDictionary* PROPERTIES_CACHE ;
- (NSString *)description
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        PROPERTIES_CACHE = @{}.mutableCopy;
    });
    
    if (!PROPERTIES_CACHE[NSStringFromClass(self.class)]){
        unsigned int count;
        objc_property_t* properties = class_copyPropertyList(self.class, &count);
        NSMutableArray* names = [[NSMutableArray alloc] initWithCapacity:count];
        for (unsigned int i = 0; i < count; ++i) {
            const char* attr = property_getAttributes(properties[i]);
            
            /* raw pointer not support valueForKey */
            if (strstr(attr, "^")) continue;
            
            [names addObject:
             [NSString stringWithFormat:@"%s",
              property_getName(properties[i])]];
        }
        free(properties);
        PROPERTIES_CACHE[NSStringFromClass(self.class)] = names;
    }
    NSArray* propertyNames = PROPERTIES_CACHE[NSStringFromClass(self.class)];
    
    NSMutableString* desc = [NSMutableString string];
    [desc appendString:@"{"];
    for (NSString* name in propertyNames) {
        if (desc.length) [desc appendString:@"\r        "];
        [desc appendFormat:@"%@:%@", name, [self valueForKey:name]];
    }
    [desc appendString:@"\r    }"];
    return desc;
}
@end
