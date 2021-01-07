//
//  KKBlock.h
//  KernelKit
//
//  Created by 黄栩生 on 2020/12/31.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

// Values for Block_layout->flags to describe block objects
enum {
    BLOCK_DEALLOCATING =      (0x0001),  // runtime
    BLOCK_REFCOUNT_MASK =     (0xfffe),  // runtime
    BLOCK_NEEDS_FREE =        (1 << 24), // runtime
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25), // compiler
    BLOCK_HAS_CTOR =          (1 << 26), // compiler: helpers have C++ code
    BLOCK_IS_GC =             (1 << 27), // runtime
    BLOCK_IS_GLOBAL =         (1 << 28), // compiler
    BLOCK_USE_STRET =         (1 << 29), // compiler: undefined if !BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE  =    (1 << 30), // compiler
    BLOCK_HAS_EXTENDED_LAYOUT=(1 << 31)  // compiler
};

typedef void(*BlockCopyFunction)(void *, const void *);
typedef void(*BlockDisposeFunction)(const void *);
typedef void(*BlockInvokeFunction)(void *, ...);

#define BLOCK_DESCRIPTOR_1 1
struct Block_descriptor_1 {
    uintptr_t reserved;
    uintptr_t size;
};

#define BLOCK_DESCRIPTOR_2 1
struct Block_descriptor_2 {
    // requires BLOCK_HAS_COPY_DISPOSE
    BlockCopyFunction copy;
    BlockDisposeFunction dispose;
};

#define BLOCK_DESCRIPTOR_3 1
struct Block_descriptor_3 {
    // requires BLOCK_HAS_SIGNATURE
    const char *signature;
    const char *layout;     // contents depend on BLOCK_HAS_EXTENDED_LAYOUT
};

struct Block_layout {
    void *isa;
    volatile int32_t flags; // contains ref count
    int32_t reserved;
    BlockInvokeFunction invoke;
    struct Block_descriptor_1 *descriptor;
    
    // requires BLOCK_HAS_COPY_DISPOSE
    //struct Block_descriptor_2 *descriptor;
    
    // requires BLOCK_HAS_SIGNATURE
    //struct Block_descriptor_3 *descriptor;
    
    // imported variables
};

typedef struct Block_layout* Block_layout_ptr;

KK_EXTERN_C_BEGIN

/**
 * get block type encoding
 */
const char* kk_block_type_encoding(id block, NSError** error);

/**
 * get block signature
 */
NSMethodSignature* kk_block_method_signature(id block, NSError** error);

/**
 *
 */
BlockInvokeFunction kk_block_invoke_function(id block, NSError** error);

BlockCopyFunction kk_block_copy_function(id block, NSError** error);

BlockDisposeFunction kk_block_dispose_function(id block, NSError** error);

KK_EXTERN_C_END
