//
//  KKFishHook.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/4.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

KK_EXTERN_C_BEGIN

@interface KKContext : NSObject
@property(nonatomic, copy, readonly) id replacement_function;
@property(nonatomic, readonly) void* replaced_function;
@property(nonatomic, readonly) NSMethodSignature* signature;
@end

/**
 * replacement block
 * need to complete arguments
 *
 */
typedef void*(^kk_replacement_function)(KKContext*);

/**
 * fish hook function with block
 */
void kk_fish_hook(NSString* func, kk_replacement_function block);

struct test_t {
    int x;
    int y;
};

int testFunc(char* a, int b);
int testFunc1(char* a, struct test_t b);

KK_EXTERN_C_END
