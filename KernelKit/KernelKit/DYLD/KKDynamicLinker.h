//
//  KKDynamicLinker.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <mach-o/loader.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKDLInfo : NSObject
@property(nonatomic) NSString* fname;       /* Pathname of shared object */
@property(nonatomic) void* fbase;           /* Base address of shared object */
@property(nonatomic) NSString* sname;       /* Name of nearest symbol */
@property(nonatomic) void* saddr;           /* Address of nearest symbol */
@end

@interface KKMachInfo : NSObject
@property(nonatomic) NSString* name;
@property(nonatomic) const struct mach_header* header;
@property(nonatomic) NSUInteger vmaddr_slice;
@end

typedef void(^kk_mach_image_callback)(const struct mach_header*,intptr_t);

@interface KKDynamicLinker : NSObject
/**
 * get info at address
 */
+ (KKDLInfo*)kk_dladdr:(const void*)addr;

/**
 *  mach image add callback
 */
+ (void)kk_register_image_add_callback:(kk_mach_image_callback)callback;
+ (void)kk_unregister_image_add_callback:(kk_mach_image_callback)callback;
/**
 *  mach image remove callback
 */
+ (void)kk_register_image_remove_callback:(kk_mach_image_callback)callback;
+ (void)kk_unregister_image_remove_callback:(kk_mach_image_callback)callback;

/**
 *  get loaded mach images
 */
+ (NSArray<KKMachInfo*>*)kk_get_loaded_mach_images;

@end

NS_ASSUME_NONNULL_END
