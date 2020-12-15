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

static inline bool is_valid_direct_key(tls_key_t k) {
    return (   k == SYNC_DATA_DIRECT_KEY
            || k == SYNC_COUNT_DIRECT_KEY
            || k == AUTORELEASE_POOL_KEY
            || k == RETURN_DISPOSITION_KEY
            );
}

void* kk_get_thread_local_storage(tls_key_t key) {
    if (!is_valid_direct_key(key)) return NULL;
    return pthread_getspecific(key);
}

void kk_set_thread_local_storage(tls_key_t key, void* value) {
    if (!is_valid_direct_key(key)) return;
    pthread_setspecific(key, value);
}
const NSDictionary* KKThreadNames =
@{
    @(KKThreadStateRunning)         : @"running",
    @(KKThreadStateStopped)         : @"stopped",
    @(KKThreadStateWaitting)        : @"waitting",
    @(KKThreadStateUnInterruptible) : @"interrupted",
    @(KKThreadStateHalted)          : @"halted"
};

@implementation KKThreadInfo
- (NSString *)description
{
    return [NSString stringWithFormat:@"name:%@ state:%@ cpu:%@",
            self.name,
            KKThreadNames[@(self.runState)],
            @(self.cpuUsage)];
}
@end

@implementation KKThread

+ (NSArray<KKThreadInfo*>*) kk_thread_infos {
    kern_return_t kr = KERN_SUCCESS;
    NSMutableArray<KKThreadInfo*>* threadInfos = [NSMutableArray array];
    
    /* 当前进程所有线程 */
    thread_array_t threads;
    mach_msg_type_number_t thread_count;
    kr = task_threads(mach_host_self(), &threads, &thread_count);
    if (kr != KERN_SUCCESS) return nil;
    
    char name[256]; /* thread name buffer */
    
    KKThreadInfo* info;
    for (uint32_t i = 0; i < thread_count; ++i) {
        info = [KKThreadInfo new];
        thread_act_t port = threads[i];
        
        /* basic info */
        integer_t tinfo[128];
        mach_msg_type_number_t thread_info_count;
        kr = thread_info(port, THREAD_BASIC_INFO, tinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) break;
        thread_basic_info_t basic_info_th = (thread_basic_info_t)tinfo;
        info.userTime = basic_info_th->user_time;
        info.systemTime = basic_info_th->system_time;
        info.runState = (KKThreadRunState)basic_info_th->run_state;
        info.suspendCount = basic_info_th->suspend_count;
        info.sleepTime = basic_info_th->sleep_time;
        info.cpuUsage = basic_info_th->cpu_usage / TH_USAGE_SCALE;
        
        /* name */
        pthread_t thread = pthread_from_mach_thread_np(port);
        memset(name, 0, sizeof(name));
        pthread_getname_np(thread, name, sizeof(name));
        info.name = [NSString stringWithUTF8String:name];
    }
    vm_deallocate(mach_thread_self(), (vm_offset_t)threads, thread_count * sizeof(thread_act_array_t));
    
    return threadInfos;
}

@end
