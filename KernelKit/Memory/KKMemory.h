//
//  KKMemory.h
//  KernelKit
//
//  Created by 黄栩生 on 2021/1/26.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

@interface KKMemory : NSObject
@property(nonatomic, readonly) NSUInteger active_size;
@property(nonatomic, readonly) NSUInteger inactive_size;
@property(nonatomic, readonly) NSUInteger wire_size;
@property(nonatomic, readonly) NSUInteger free_size;
@property(nonatomic, readonly) NSUInteger resident_size;
@property(nonatomic, readonly) NSUInteger virtual_size;
@property(nonatomic, readonly) NSUInteger phys_footprint;
@end

KK_EXTERN_C_BEGIN

/**
 * get memory info
 */
KKMemory* kk_memory(void);

KK_EXTERN_C_END

