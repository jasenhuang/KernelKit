//
//  KKDynamicLinker.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKDynamicLinker.h"
#import <dlfcn.h>

@interface KKDLInfo()

@end

@implementation KKDLInfo

@end

@implementation KKDynamicLinker

+ (KKDLInfo*)dladdr:(const void*)addr {
    /** If an image containing addr cannot be found, dladdr() returns 0.
     * On success, a non-zero value is returned.
     */
    Dl_info dlinfo;
    if (dladdr(addr, &dlinfo) == 0) return nil;
        
    KKDLInfo* info = [KKDLInfo new];
    info.fname = [NSString stringWithUTF8String:dlinfo.dli_fname];
    info.fbase = dlinfo.dli_fbase;
    info.sname = [NSString stringWithUTF8String:dlinfo.dli_sname];
    info.saddr = dlinfo.dli_saddr;
    
    return info;
}



@end
