//
//  KKSignalHandler.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * greate implement from KSCrash
 * https://github.com/kstenerud/KSCrash
 *
 */

typedef int kk_signal;
typedef void(^kk_signal_callback)(kk_signal);

@interface KKSignalHandler : NSObject

/**
 * register callback for signal
 */
+ (void)kk_register_signal:(kk_signal)signal callback:(kk_signal_callback)callback;

/**
 * register callback for common fatal signal
 */
+ (void)kk_register_signals_callback:(kk_signal_callback)callback;

@end

NS_ASSUME_NONNULL_END
