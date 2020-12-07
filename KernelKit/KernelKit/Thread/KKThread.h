//
//  KKThread.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <mach/time_value.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, KKThreadRunState) {
    KKThreadStateRunning            = 1,        /* thread is running normally */
    KKThreadStateStopped            = 2,        /* thread is stopped */
    KKThreadStateWaitting           = 3,        /* thread is waiting normally */
    KKThreadStateUnInterruptible    = 4,        /* thread is in an uninterruptible wait */
    KKThreadStateHalted             = 5,        /* thread is halted at a clean point */
};

@interface KKThreadInfo : NSObject
@property(nonatomic) NSString* name;
@property(nonatomic) time_value_t userTime;         /* user run time */
@property(nonatomic) time_value_t systemTime;       /* system run time */
@property(nonatomic) double cpuUsage;               /* scaled cpu usage percentage */
@property(nonatomic) KKThreadRunState runState;     /* run state */
@property(nonatomic) NSInteger suspendCount;        /* suspend count for thread */
@property(nonatomic) NSInteger sleepTime;           /* number of seconds that thread has been sleeping */
@end

@interface KKThread : NSObject

/**
 * get all thread infos
 */
+ (NSArray<KKThreadInfo*>*)thread_infos;

@end

NS_ASSUME_NONNULL_END
