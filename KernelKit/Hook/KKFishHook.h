//
//  KKFishHook.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/4.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

KK_EXTERN_C_BEGIN

typedef char* KKType;
#define KKVarList   \
_1, _2, _3,         \
_4, _5, _6,         \
_7, _8, _9,         \
_10, _11, _12,      \
_13, _14, _15

#define KKTypeList \
KKType _1, KKType _2, KKType _3,    \
KKType _4, KKType _5, KKType _6,    \
KKType _7, KKType _8, KKType _9,    \
KKType _10, KKType _11, KKType _12, \
KKType _13, KKType _14, KKType _15

@interface KKToken : NSObject
- (void)restore;
@end

/**
 * replacement block
 * need to complete arguments
 *
 */
typedef void*(^kk_replacement_function)(void* replaced);

/**
 * fish hook function with block
 */
KKToken* kk_fish_hook(NSString* func, kk_replacement_function block);

KK_EXTERN_C_END
