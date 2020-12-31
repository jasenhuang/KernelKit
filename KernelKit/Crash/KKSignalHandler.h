//
//  KKSignalHandler.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/7.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

/**
 * greate implement from KSCrash
 * https://github.com/kstenerud/KSCrash
 *
 */

KK_EXTERN_C_BEGIN

typedef int kk_signal;
typedef void(^kk_signal_callback)(kk_signal);

/**
 * register callback for signal
 */
void kk_register_signal_callback(kk_signal signal, kk_signal_callback callback);

/**
 * unregister callback for signal
 */
void kk_unregister_signal_callback(kk_signal signal, kk_signal_callback callback);

/**
 * register callback for common fatal signals
 */
void kk_register_signals_callback(kk_signal_callback callback);

/**
 * unregister callback for common fatal signals
 */
void kk_unregister_signals_callback(kk_signal_callback callback);

KK_EXTERN_C_END
