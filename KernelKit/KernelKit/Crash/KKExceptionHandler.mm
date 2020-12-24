//
//  KKCrashHandler.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/17.
//

#import "KKExceptionHandler.h"

static NSUncaughtExceptionHandler* _kk_previousExceptionHandler;

static NSMutableArray* _kk_exception_callbacks = @[].mutableCopy;

static void handleException(NSException* exception) {
    NSLog(@"Trapped exception %@", exception);
    /* handle exception */
    
    /* call previsous handler */
    _kk_previousExceptionHandler(exception);
}

#pragma NSException handler interception
void installExceptionHandler() {
    NSLog(@"Setting new exception handler.");
    _kk_previousExceptionHandler = NSGetUncaughtExceptionHandler();
    
    NSSetUncaughtExceptionHandler(&handleException);
}

void uninstallExceptionHandler() {
    NSLog(@"Restoring original handler.");
    
    NSSetUncaughtExceptionHandler(_kk_previousExceptionHandler);
}

/**
 * register callback for exception
 */
void kk_register_exception_callback(kk_exception_callback callback) {
    if (!_kk_previousExceptionHandler) installExceptionHandler();
    [_kk_exception_callbacks addObject:callback];
}

/**
 * unregister callback for exception
 */
void kk_unregister_exception_callback(kk_exception_callback callback) {
    [_kk_exception_callbacks removeObject:callback];
}
