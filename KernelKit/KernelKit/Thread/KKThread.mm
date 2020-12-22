//
//  KKThread.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKThread.h"
#import <pthread/pthread.h>
#import <mach/mach.h>
#import <mach/mach_types.h>
#import "KKMacros.h"

const NSDictionary* KKThreadNames =
@{
    @(KKThreadStateRunning)         : @"running",
    @(KKThreadStateStopped)         : @"stopped",
    @(KKThreadStateWaitting)        : @"waitting",
    @(KKThreadStateUnInterruptible) : @"interrupted",
    @(KKThreadStateHalted)          : @"halted"
};

inline NSTimeInterval kk_time_value(time_value time) {
    return time.seconds + (double)time.microseconds / 1000000;
}

@interface KKThread()
@property(nonatomic, readwrite) unsigned int port;
- (instancetype)initWithPort:(unsigned int)port;
@end

/**
 * get current thread
 */
KKThread* kk_thread_self() {
    KKThread* thread = [[KKThread alloc] initWithPort:mach_thread_self()];
    return thread;
}

/**
 * get all threads
 */
NSArray<KKThread*>* kk_all_threads() {
    kern_return_t kr = KERN_SUCCESS;
    NSMutableArray<KKThread*>* kkThreads = [NSMutableArray array];
    
    /* 当前进程所有线程 */
    thread_array_t threads;
    mach_msg_type_number_t thread_count;
    kr = task_threads(mach_task_self(), &threads, &thread_count);
    if (kr != KERN_SUCCESS) return nil;
    
    KKThread* kkThread;
    for (uint32_t i = 0; i < thread_count; ++i) {
        kkThread = [[KKThread alloc] init];
        kkThread.port = threads[i];
        [kkThreads addObject:kkThread];
    }
    vm_deallocate(mach_thread_self(), (vm_offset_t)threads, thread_count * sizeof(thread_act_array_t));
    
    return kkThreads;
}

@implementation KKThreadInfo

@end

@implementation KKThread

- (instancetype)initWithPort:(unsigned int)port
{
    if (self = [self init]) {
        _port = port;
    }
    return self;
}
/**
 * properties
 */
- (NSString*)name {
    char name[256]; /* thread name buffer */
    memset(name, 0, sizeof(name));
    pthread_getname_np(self.thread, name, sizeof(name));
    return [NSString stringWithUTF8String:name];
}

- (pthread_t)thread {
    return pthread_from_mach_thread_np(self.port);
}

/**
 * thread detail infos
 */
- (KKThreadInfo*)threadInfos {
    kern_return_t kr = KERN_SUCCESS;
    KKThreadInfo* info = [[KKThreadInfo alloc] init];
    
    /* basic info */
    integer_t tinfo[128];
    mach_msg_type_number_t thread_info_count;
    kr = thread_info(self.port, THREAD_BASIC_INFO, tinfo, &thread_info_count);
    if (kr != KERN_SUCCESS) return nil;
    
    thread_basic_info_t basic_info_th = (thread_basic_info_t)tinfo;
    info.name = self.name;
    info.userTime = kk_time_value(basic_info_th->user_time);
    info.systemTime = kk_time_value(basic_info_th->system_time);
    info.runState = (KKThreadRunState)basic_info_th->run_state;
    info.suspendCount = basic_info_th->suspend_count;
    info.sleepTime = basic_info_th->sleep_time;
    info.cpuUsage = basic_info_th->cpu_usage / TH_USAGE_SCALE;
    
    return info;
}

/**
 * suspend thread
 */
- (BOOL)suspend {
    return (KERN_SUCCESS ==
            thread_suspend(self.port));
}

/**
 * resume thread
 */
- (BOOL)resume {
    return (KERN_SUCCESS ==
            thread_resume(self.port));
}

/**
 * terminate thread
 */
- (BOOL)terminate {
    return (KERN_SUCCESS ==
            thread_terminate(self.port));
}

@end
