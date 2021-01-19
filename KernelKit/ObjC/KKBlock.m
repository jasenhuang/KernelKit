//
//  KKBlock.m
//  KernelKit
//
//  Created by 黄栩生 on 2020/12/31.
//

#import "KKBlock.h"

NSString* const KKBlockDomain = @"me.jasen.KenelKit.KKBlock";

void _kk_block_error(NSError** error, int code, id msg) {
    if (error){
        *error = [NSError errorWithDomain:KKBlockDomain
                                     code:code
                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
    }
}

/**
 * get block type encoding
 */
const char* kk_block_type_encoding(id block, NSError** error) {
    Block_layout_ptr layout = (__bridge void*)block;
    if (!(layout->flags & BLOCK_HAS_SIGNATURE)){
        NSString *description =
        [NSString stringWithFormat:@"The block %@ doesn't contain a type signature.",
         block];
        _kk_block_error(error, -1, description);
        return nil;
    }
    void *desc = layout->descriptor;
    desc += sizeof(struct Block_descriptor_1);
    if (layout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct Block_descriptor_2);
    }
    if (!desc) {
        NSString *description =
        [NSString stringWithFormat:@"The block %@ doesn't has a type signature.",
         block];
        _kk_block_error(error, -2, description);
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return signature;
}

/**
 * get block signature
 */
NSMethodSignature* kk_block_method_signature(id block, NSError** error) {
    const char *signature = kk_block_type_encoding(block, error);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

/**
 * get block invoke
 */
BlockInvokeFunction kk_block_invoke_function(id block, NSError** error) {
    Block_layout_ptr layout = (__bridge void*)block;
    return layout->invoke;
}

/**
 * get block copy
 */
BlockCopyFunction kk_block_copy_function(id block, NSError** error) {
    Block_layout_ptr layout = (__bridge void*)block;
    void *desc = layout->descriptor;
    desc += sizeof(struct Block_descriptor_1);
    if (layout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct Block_descriptor_2);
    }
    //TODO
    return NULL;
}


/**
 * get block dispose
 */
BlockDisposeFunction kk_block_dispose_function(id block, NSError** error) {
    Block_layout_ptr layout = (__bridge void*)block;
    void *desc = layout->descriptor;
    desc += sizeof(struct Block_descriptor_1);
    if (layout->flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(struct Block_descriptor_2);
    }
    //TODO
    return NULL;
}
