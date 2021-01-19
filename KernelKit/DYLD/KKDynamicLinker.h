//
//  KKDynamicLinker.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKDescribable.h>
#import <KernelKit/KKMacros.h>
#import <mach-o/loader.h>

@interface KKDLInfo : KKDescribable
@property(nonatomic) NSString* fname;       /* Pathname of shared object */
@property(nonatomic) void* fbase;           /* Base address of shared object */
@property(nonatomic) NSString* sname;       /* Name of nearest symbol */
@property(nonatomic) void* saddr;           /* Address of nearest symbol */
@end

@interface KKMachInfo : KKDescribable
@property(nonatomic) NSString* name;
@property(nonatomic) const struct mach_header* header;
@property(nonatomic) NSUInteger vmaddr_slice;
@end

KK_EXTERN_C_BEGIN

typedef void(^kk_mach_image_callback)(const struct mach_header* _Nonnull,intptr_t);

/**
 * get info at address
 */
KKDLInfo* _Nullable kk_dladdr(const void* _Nullable addr);

/**
 *  register mach image add callback
 */
void kk_register_image_add_callback(kk_mach_image_callback _Nullable callback);

/**
 *  un register mach image add callback
 */
void kk_unregister_image_add_callback(kk_mach_image_callback _Nullable callback);

/**
 *  register mach image remove callback
 */
void kk_register_image_remove_callback(kk_mach_image_callback _Nullable callback);

/**
 *  unregister mach image remove callback
 */
void kk_unregister_image_remove_callback(kk_mach_image_callback _Nullable callback);

/**
 *  get loaded mach images
 */
NSArray<KKMachInfo*>* _Nullable kk_get_loaded_mach_images();

KK_EXTERN_C_END
