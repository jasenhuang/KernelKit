//
//  KKMemory.m
//  KernelKit
//
//  Created by 黄栩生 on 2021/1/26.
//

#import "KKMemory.h"
#import <sys/stat.h>
#import <mach/mach_host.h>
#import <mach/task.h>

@interface KKMemory()
@property(nonatomic, readwrite) NSUInteger active_size;
@property(nonatomic, readwrite) NSUInteger inactive_size;
@property(nonatomic, readwrite) NSUInteger wire_size;
@property(nonatomic, readwrite) NSUInteger free_size;
@property(nonatomic, readwrite) NSUInteger resident_size;
@property(nonatomic, readwrite) NSUInteger virtual_size;
@property(nonatomic, readwrite) NSUInteger phys_footprint;
@end

@implementation KKMemory

@end

KKMemory* kk_memory() {
    mach_port_t           host_port = mach_host_self();
    mach_msg_type_number_t   host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t               pagesize;
    vm_statistics_data_t     vm_stat;
    
    host_page_size(host_port, &pagesize);
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
    }
    
    struct task_vm_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&info, &size);
    if (kerr != KERN_SUCCESS){
        NSLog(@"Failed to fetch task vm info");
    }
    
    KKMemory* memory = [[KKMemory alloc] init];
    
    memory.active_size = vm_stat.active_count * pagesize;
    memory.inactive_size = vm_stat.inactive_count * pagesize;
    memory.wire_size = vm_stat.wire_count * pagesize;
    memory.free_size = vm_stat.free_count * pagesize;
    memory.resident_size = info.resident_size;
    memory.virtual_size = info.virtual_size;
    memory.phys_footprint = info.phys_footprint;
    
    return memory;
}
