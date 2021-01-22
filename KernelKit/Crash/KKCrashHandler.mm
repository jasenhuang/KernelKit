//
//  KKCrashHandler.m
//  KernelKit
//
//  Created by 黄栩生 on 2021/1/19.
//

#import "KKCrashHandler.h"
#import "KKSignalHandler.h"
#import "KKExceptionHandler.h"
#import "KKTerminationHandler.h"

static KKCrashHandler kk_crash_handlers[] = {
    {
        .type = KKCrashHandlerTypeSignal,
        .setEnabled = kk_enable_signal_handler,
        .isEnabled = is_kk_signal_handler_enabled
    },
    {
        .type = KKCrashHandlerTypeException,
        .setEnabled = kk_enable_exception_handler,
        .isEnabled = is_kk_exception_handler_enabled
    },
    {
        .type = KKCrashHandlerTypeTermination,
        .setEnabled = kk_enable_termination_handler,
        .isEnabled = is_kk_termination_handler_enabled
    }
};

static NSInteger kk_crash_handler_count = sizeof(kk_crash_handlers) / sizeof(KKCrashHandler);

void _kk_enable_crash_handler(KKCrashHandler handler, BOOL enabled) {
    if (handler.isEnabled() != enabled){
        handler.setEnabled(enabled);
    }
}

void kk_enable_crash_handler(KKCrashHandlerType type, BOOL enabled) {
    NSInteger count = kk_crash_handler_count;
    for (NSInteger i = 0; i < count; ++i) {
        if (kk_crash_handlers[i].type == type){
            _kk_enable_crash_handler(kk_crash_handlers[i], enabled);
        }
    }
}

void kk_enable_crash_handlers(bool enabled) {
    NSInteger count = kk_crash_handler_count;
    for (NSInteger i = 0; i < count; ++i) {
        _kk_enable_crash_handler(kk_crash_handlers[i], enabled);
    }
}

static NSMutableArray* _kk_compound_callbacks = @[].mutableCopy;

/**
 * register callback for crash
 */
void kk_register_crash_callback(kk_crash_callback callback) {
    kk_enable_crash_handlers(true);
    
    kk_register_signals_callback(^(kk_signal signal) {
        if (callback) callback(KKCrashHandlerTypeSignal, @{@"signal":@(signal)});
    });
    kk_register_exception_callback(^(NSException *exception) {
        if (callback) callback(KKCrashHandlerTypeException, @{@"exception":exception});
    });
    kk_register_termination_callback(^(KKTermination *termination) {
        if (callback) callback(KKCrashHandlerTypeTermination, @{@"termination":termination});
    });
}

/**
 * unregister callback for crash
 */
void kk_unregister_crash_callback(kk_crash_callback callback) {
    if (!callback) return ;
    //TODO
}
