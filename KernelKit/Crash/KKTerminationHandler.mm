//
//  KKCPPExceptionHandler.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/23.
//

#import "KKTerminationHandler.h"
#import <KernelKit/KKDynamicLinker.h>
#import <cxxabi.h>
#import <stdio.h>
#import <stdlib.h>
#import <typeinfo>
#import <dlfcn.h>
#import <typeinfo>

static std::terminate_handler _kk_previsouTerminationHandler;

static NSMutableArray* _kk_termination_callbacks = @[].mutableCopy;

static void handleTermination() {
    NSLog(@"Trapped c++ exception");
    
    /* handle termination */
    const char* name = NULL;
    std::type_info* tinfo = __cxxabiv1::__cxa_current_exception_type();
    if(tinfo != NULL) name = tinfo->name();
    if(name == NULL || strcmp(name, "NSException") != 0){
        
    }
    
    /* call previsous handler */
    _kk_previsouTerminationHandler();
}

#pragma Termination handler interception
void installTerminationHandler() {
    NSLog(@"Setting new exception handler.");
    _kk_previsouTerminationHandler = NULL;
    
}

void uninstallTerminationHandler() {
    NSLog(@"Restoring original handler.");
    
}

/**
 * register callback for exception
 */
void kk_register_exception_callback(kk_termination_callback callback) {
    if (!_kk_previsouTerminationHandler) installTerminationHandler();
    [_kk_termination_callbacks addObject:callback];
}

/**
 * unregister callback for exception
 */
void kk_unregister_exception_callback(kk_termination_callback callback) {
    [_kk_termination_callbacks removeObject:callback];
}
