//
//  KKDynamicLinker.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KKDLInfo : NSObject
@property(nonatomic) NSString* fname;       /* Pathname of shared object */
@property(nonatomic) void* fbase;           /* Base address of shared object */
@property(nonatomic) NSString* sname;       /* Name of nearest symbol */
@property(nonatomic) void* saddr;           /* Address of nearest symbol */
@end

@interface KKDynamicLinker : NSObject

/**
 * 
 */
+ (KKDLInfo*)dladdr:(const void*)addr;

@end

NS_ASSUME_NONNULL_END
