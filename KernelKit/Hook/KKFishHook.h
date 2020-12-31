//
//  KKFishHook.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/4.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

KK_EXTERN_C_BEGIN

typedef void*(*kk_replaced_function)(...);

typedef void*(^kk_replacement_function)(kk_replaced_function, ...);

#define _kk_replaced_function(func, ...) func(__VA_ARGS__);

#define _kk_replacement_function(...) void*(^)(kk_replaced_function, __VA_ARGS__);


/**
 * fish hook function
 */
void kk_fish_hook(NSString* func, kk_replacement_function block);


KK_EXTERN_C_END
