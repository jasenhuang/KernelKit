//
//  KKSignalHandler.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/7.
//

#import "KKSignalHandler.h"
#import "KKLog.h"

typedef void(*kk_sa_handler)(int);
typedef void(*kk_sa_sigaction)(int, siginfo_t *, void *);

static const int _kk_fatalSignals[] = {
    SIGABRT,
    SIGBUS,
    SIGFPE,
    SIGILL,
    SIGPIPE,
    SIGSEGV,
    SIGSYS,
    SIGTRAP,
};

static struct sigaction* _kk_previousSignalHandlers = NULL;

static const int _kk_fatalSignalsCount = sizeof(_kk_fatalSignals) / sizeof(*_kk_fatalSignals);

static NSMutableDictionary* _kk_signal_callbacks = @{}.mutableCopy;

static void handleSignal(int sigNum, siginfo_t* signalInfo, void* userContext) {
    NSLog(@"Trapped signal %d", sigNum);
    /* handle signal */
    
    NSArray* blocks = _kk_signal_callbacks[@(sigNum)];
    for (kk_signal_callback block in blocks) {
        block(sigNum);
    }
    
    /* call previsous handler */
    int i = 0;
    for(; i < _kk_fatalSignalsCount; ++i) if (sigNum == _kk_fatalSignals[i]) break;
    if (_kk_previousSignalHandlers) {
        struct sigaction* action = &_kk_previousSignalHandlers[i];
        if (action->sa_sigaction){
            action->sa_sigaction(sigNum, signalInfo, userContext);
        }else if (action->sa_handler){
            action->sa_handler(sigNum);
        }
    }
    
    NSLog(@"Re-raising signal for regular handlers to catch.");
    // This is technically not allowed, but it works in OSX and iOS.
    raise(sigNum);
}

@implementation KKSignalHandler
/**
 * register callback for signal
 */
+ (void)kk_register_signal:(kk_signal)signal callback:(kk_signal_callback)callback {
    if (!_kk_previousSignalHandlers) [KKSignalHandler installSignalHandler];
    NSMutableArray* blocks = _kk_signal_callbacks[@(signal)];
    if (!blocks) blocks = @[].mutableCopy;
    [blocks addObject:callback];
}

/**
 * register callback for common fatal signal
 */
+ (void)kk_register_signals_callback:(kk_signal_callback)callback {
    if (!_kk_previousSignalHandlers) [KKSignalHandler installSignalHandler];
    
    for (int i = 0 ; i < _kk_fatalSignalsCount; ++i){
        [self kk_register_signal:_kk_fatalSignals[i] callback:callback];
    }
}

#pragma signal handler interception
+ (void)installSignalHandler {
    if (_kk_previousSignalHandlers) return ;
    NSLog(@"Installing signal handler.");
    
    NSLog(@"Allocating memory to store previous signal handlers.");
    _kk_previousSignalHandlers = (struct sigaction*)malloc(sizeof(*_kk_previousSignalHandlers)
                                      * (unsigned)_kk_fatalSignalsCount);
    struct sigaction action = {{0}};
    action.sa_flags = SA_SIGINFO | SA_ONSTACK;
#if __APPLE__ || defined(__LP64__)
    action.sa_flags |= SA_64REGSET;
#endif
    sigemptyset(&action.sa_mask);
    action.sa_sigaction = &handleSignal;
    
    for (int i = 0 ; i < _kk_fatalSignalsCount; ++i){
        if (0 != sigaction(_kk_fatalSignals[i], &action, &_kk_previousSignalHandlers[i])) {
            NSLog(@"Installing signal handler.");
            break;
        }
    }
}

+ (void)uninstallSignalHandler {
    NSLog(@"Uninstalling signal handlers.");
    
    for (int i = 0 ; i < _kk_fatalSignalsCount; ++i){
        if (0 != sigaction(_kk_fatalSignals[i], &_kk_previousSignalHandlers[i], NULL)) {
            NSLog(@"Installing signal handler.");
            break;
        }
    }
    free(_kk_previousSignalHandlers);
    _kk_previousSignalHandlers = NULL;
}

@end
