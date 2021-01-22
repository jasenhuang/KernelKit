//
//  KKCPPExceptionHandler.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/23.
//

#import "KKTerminationHandler.h"
#import "KKCrashHandler.h"
#import <cxxabi.h>
#import <stdio.h>
#import <stdlib.h>
#import <typeinfo>
#import <dlfcn.h>
#import <typeinfo>

@implementation KKTermination

@end

static std::terminate_handler _kk_previsouTerminationHandler;

static NSMutableArray* _kk_termination_callbacks = @[].mutableCopy;

static bool _kk_termination_handler_enabled = false;

// Compiler hints for "if" statements
#define likely_if(x) if(__builtin_expect(x,1))
#define unlikely_if(x) if(__builtin_expect(x,0))

typedef void (*cxa_throw_type)(void*, std::type_info*, void (*)(void*));

extern "C"
{
    void __cxa_throw(void* thrown_exception, std::type_info* tinfo, void (*dest)(void*)) __attribute__ ((weak));

    void __cxa_throw(void* thrown_exception, std::type_info* tinfo, void (*dest)(void*))
    {
        static cxa_throw_type orig_cxa_throw = NULL;
        
        unlikely_if(orig_cxa_throw == NULL)
        {
            orig_cxa_throw = (cxa_throw_type) dlsym(RTLD_NEXT, "__cxa_throw");
        }
        orig_cxa_throw(thrown_exception, tinfo, dest);
        __builtin_unreachable();
    }
}

static void handleTermination() {
    NSLog(@"Trapped c++ exception");
    
    /* handle termination */
    const char* name = NULL;
    std::type_info* tinfo = __cxxabiv1::__cxa_current_exception_type();
    if(tinfo != NULL) name = tinfo->name();
    if(name == NULL || strcmp(name, "NSException") != 0){
        char descriptionBuff[1024];
        const char* description = descriptionBuff;
        descriptionBuff[0] = 0;
        
        NSLog(@"Discovering what kind of exception was thrown.");
        try
        {
            throw;
        }
        catch(std::exception& exc)
        {
            strncpy(descriptionBuff, exc.what(), sizeof(descriptionBuff));
        }
#define CATCH_VALUE(TYPE, PRINTFTYPE) \
catch(TYPE value)\
{ \
    snprintf(descriptionBuff, sizeof(descriptionBuff), "%" #PRINTFTYPE, value); \
}
        CATCH_VALUE(char,                 d)
        CATCH_VALUE(short,                d)
        CATCH_VALUE(int,                  d)
        CATCH_VALUE(long,                ld)
        CATCH_VALUE(long long,          lld)
        CATCH_VALUE(unsigned char,        u)
        CATCH_VALUE(unsigned short,       u)
        CATCH_VALUE(unsigned int,         u)
        CATCH_VALUE(unsigned long,       lu)
        CATCH_VALUE(unsigned long long, llu)
        CATCH_VALUE(float,                f)
        CATCH_VALUE(double,               f)
        CATCH_VALUE(long double,         Lf)
        CATCH_VALUE(char*,                s)
        catch(...)
        {
            description = NULL;
        }
        
        KKTermination* termination;
        NSArray* blocks = _kk_termination_callbacks;
        for (kk_termination_callback block in blocks) {
            termination = [[KKTermination alloc] init];
            if (name) termination.name = [NSString stringWithUTF8String:name];
            if (description) termination.desc = [NSString stringWithUTF8String:description];
            block(termination);
        }
    }
    
    /* disable all handlers */
    kk_enable_crash_handlers(false);
    
    /* call previsous handler */
    if (_kk_previsouTerminationHandler)
        _kk_previsouTerminationHandler();
}

#pragma Termination handler interception
void installTerminationHandler() {
    NSLog(@"Setting termination handler.");
    _kk_previsouTerminationHandler = std::set_terminate(handleTermination);
    
}

void uninstallTerminationHandler() {
    NSLog(@"Restoring termination handler.");
    std::set_terminate(_kk_previsouTerminationHandler);
}

/**
 * register callback for termination
 */
void kk_register_termination_callback(kk_termination_callback callback) {
    kk_enable_termination_handler(true);
    
    [_kk_termination_callbacks addObject:callback];
}

/**
 * unregister callback for termination
 */
void kk_unregister_termination_callback(kk_termination_callback callback) {
    [_kk_termination_callbacks removeObject:callback];
}

/**
 * enable handler
 */
void kk_enable_termination_handler(bool enabled) {
    if (_kk_termination_handler_enabled != enabled){
        _kk_termination_handler_enabled = enabled;
        enabled ? installTerminationHandler() : uninstallTerminationHandler();
    }
}

/**
 * is handler enabled
 */
bool is_kk_termination_handler_enabled(void) {
    return _kk_termination_handler_enabled;
}
