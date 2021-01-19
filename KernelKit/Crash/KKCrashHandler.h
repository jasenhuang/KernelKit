//
//  KKCrashHandler.h
//  KernelKit
//
//  Created by 黄栩生 on 2021/1/19.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

/**
 * greate implement from KSCrash
 * https://github.com/kstenerud/KSCrash
 *
 */

KK_EXTERN_C_BEGIN

typedef NS_ENUM(NSUInteger, KKCrashHandlerType) {
    KKCrashHandlerTypeSignal = 1,
    KKCrashHandlerTypeException,
    KKCrashHandlerTypeTermination,
};

typedef struct {
    KKCrashHandlerType type;
    void (* _Nullable setEnabled)(bool isEnabled);
    bool (* _Nullable isEnabled)(void);
} KKCrashHandler;

/**
 * config crash handler of type
 */
void kk_enable_crash_handler(KKCrashHandlerType type, BOOL enabled);

/**
 * config all crash handlers
 */
void kk_enable_crash_handlers(bool enabled);

/**
 * signal: @(signal)
 * exception: NSException
 * termination: KKTermination
 */
typedef void(^kk_crash_callback)(KKCrashHandlerType, NSDictionary*_Nullable);

/**
 * register callback for crash
 */
void kk_register_crash_callback(kk_crash_callback _Nullable callback);

/**
 * unregister callback for crash
 */
void kk_unregister_crash_callback(kk_crash_callback _Nullable callback);


KK_EXTERN_C_END
