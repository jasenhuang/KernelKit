//
//  KKCrashHandler.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/17.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

/**
 * greate implement from KSCrash
 * https://github.com/kstenerud/KSCrash
 *
 */

KK_EXTERN_C_BEGIN

typedef void(^kk_exception_callback)(NSException*);

/**
 * register callback for exception
 */
void kk_register_exception_callback(kk_exception_callback callback);

/**
 * unregister callback for exception
 */
void kk_unregister_exception_callback(kk_exception_callback callback);

/**
 * enable handler
 */
void kk_enable_exception_handler(bool enabled);

/**
 * is handler enabled
 */
bool is_kk_exception_handler_enabled(void);

KK_EXTERN_C_END
