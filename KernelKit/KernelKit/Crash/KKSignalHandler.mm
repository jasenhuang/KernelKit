//
//  KKSignalHandler.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/7.
//

#import "KKSignalHandler.h"
#import "KKMacros.h"

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
            NSLog(@"sa_sigaction");
            action->sa_sigaction(sigNum, signalInfo, userContext);
        }else if (action->sa_handler){
            NSLog(@"sa_handler");
            action->sa_handler(sigNum);
        }
    }
    
    //NSLog(@"Re-raising signal for regular handlers to catch.");
    // This is technically not allowed, but it works in OSX and iOS.
    //raise(sigNum);
}

#pragma signal handler interception
void installSignalHandler() {
    if (_kk_previousSignalHandlers) return ;
    NSLog(@"Installing signal handler.");
    
    /* Allocating memory to store previous signal handlers." */
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
            NSLog(@"install sigaction (%d): %s", _kk_fatalSignals[i], strerror(errno));
            break;
        }
    }
}

void uninstallSignalHandler() {
    NSLog(@"Uninstalling signal handlers.");
    
    for (int i = 0 ; i < _kk_fatalSignalsCount; ++i){
        if (0 != sigaction(_kk_fatalSignals[i], &_kk_previousSignalHandlers[i], NULL)) {
            NSLog(@"uninstall sigaction (%d): %s", _kk_fatalSignals[i], strerror(errno));
            break;
        }
    }
    free(_kk_previousSignalHandlers);
    _kk_previousSignalHandlers = NULL;
}

/**
 * register callback for signal
 */
void kk_register_signal(kk_signal signal, kk_signal_callback callback) {
    if (!_kk_previousSignalHandlers) installSignalHandler();
    NSMutableArray* blocks = _kk_signal_callbacks[@(signal)];
    if (!blocks) {
        blocks = @[].mutableCopy;
        _kk_signal_callbacks[@(signal)] = blocks;
    }
    [blocks addObject:callback];
}

/**
 * unregister callback for signal
 */
void kk_unregister_signal(kk_signal signal, kk_signal_callback callback) {
    NSMutableArray* blocks = _kk_signal_callbacks[@(signal)];
    [blocks removeObject:callback];
}

/**
 * register callback for common fatal signals
 */
void kk_register_signals_callback(kk_signal_callback callback) {
    if (!_kk_previousSignalHandlers) installSignalHandler();
    
    for (int i = 0 ; i < _kk_fatalSignalsCount; ++i){
        kk_register_signal(_kk_fatalSignals[i], callback);
    }
}

/**
 * unregister callback for common fatal signals
 */
void kk_unregister_signals_callback(kk_signal_callback callback) {
    for (int i = 0 ; i < _kk_fatalSignalsCount; ++i){
        kk_unregister_signal(_kk_fatalSignals[i], callback);
    }
}
