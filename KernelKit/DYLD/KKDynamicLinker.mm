//
//  KKDynamicLinker.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKDynamicLinker.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>

@implementation KKDLInfo
@end

@implementation KKMachInfo
@end

KKDLInfo* kk_dladdr(const void* _Nullable addr) {
    if (NULL == addr) return nil;
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

static NSMutableDictionary* _kk_mach_image_sets = @{}.mutableCopy;
NSArray<KKMachInfo*>* kk_get_loaded_mach_images() {
    KKMachInfo* info;
    NSMutableArray<KKMachInfo*>* infos = [NSMutableArray array];
    
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; ++i) {
        info = [[KKMachInfo alloc] init];
        info.name = [NSString stringWithUTF8String:_dyld_get_image_name(i)];
        info.header = _dyld_get_image_header(i);
        info.vmaddr_slice = _dyld_get_image_vmaddr_slide(i);
        [infos addObject:info];
        [_kk_mach_image_sets setObject:info forKey:@(info.vmaddr_slice)];
    }
    
    return infos;
}

static NSMutableArray* _kk_add_blocks = @[].mutableCopy;
static void dyld_image_add_callback(const struct mach_header* header,
                                    intptr_t slice) {
    for (kk_mach_image_callback block in _kk_add_blocks) {
        block(header, slice);
    }
}

void kk_register_image_add_callback(kk_mach_image_callback callback) {
    if (!callback) return;
    [_kk_add_blocks addObject:callback];
    _dyld_register_func_for_add_image(dyld_image_add_callback);
}

void kk_unregister_image_add_callback(kk_mach_image_callback callback) {
    if (!callback) return;
    [_kk_add_blocks removeObject:callback];
}

static NSMutableArray* _kk_remove_blocks = @[].mutableCopy;
static void dyld_image_remove_callback(const struct mach_header* header,
                                       intptr_t slice) {
    for (void(^block)(const struct mach_header*, intptr_t) in _kk_remove_blocks) {
        block(header, slice);
    }
}

void kk_register_image_remove_callback(kk_mach_image_callback callback) {
    if (!callback) return;
    [_kk_remove_blocks addObject:callback];
    _dyld_register_func_for_remove_image(dyld_image_remove_callback);
}

void kk_unregister_image_remove_callback(kk_mach_image_callback callback) {
    if (!callback) return;
    [_kk_remove_blocks removeObject:callback];
}

