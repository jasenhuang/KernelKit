//
//  KKThread.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKDescribable.h>
#import <KernelKit/KKMacros.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, KKThreadRunState) {
    KKThreadStateRunning            = 1,        /* thread is running normally */
    KKThreadStateStopped            = 2,        /* thread is stopped */
    KKThreadStateWaitting           = 3,        /* thread is waiting normally */
    KKThreadStateUnInterruptible    = 4,        /* thread is in an uninterruptible wait */
    KKThreadStateHalted             = 5,        /* thread is halted at a clean point */
};

@class KKThread, KKThreadInfo;

KK_EXTERN_C_BEGIN
/**
 * get current thread
 */
KKThread* kk_thread_self();
/**
 * get all threads
 */
NSArray<KKThread*>* kk_all_threads();

KK_EXTERN_C_END


@interface KKThreadInfo : KKDescribable
@property(nonatomic) NSString* name;
@property(nonatomic) double cpuUsage;                   /* scaled cpu usage percentage */
@property(nonatomic) NSTimeInterval userTime;           /* user run time */
@property(nonatomic) NSTimeInterval systemTime;         /* system run time */
@property(nonatomic) KKThreadRunState runState;         /* run state */
@property(nonatomic) NSInteger suspendCount;            /* suspend count for thread */
@property(nonatomic) NSInteger sleepTime;               /* number of seconds that thread has been sleeping */
@end

@interface KKThread : KKDescribable
@property(nonatomic, readonly) NSString* name;
@property(nonatomic, readonly) pthread_t thread;

/**
 * thread detail infos
 */
- (KKThreadInfo*)threadInfos;

/**
 * suspend thread
 */
- (BOOL)suspend;

/**
 * resume thread
 */
- (BOOL)resume;

/**
 * terminate thread
 */
- (BOOL)terminate;

@end

NS_ASSUME_NONNULL_END
