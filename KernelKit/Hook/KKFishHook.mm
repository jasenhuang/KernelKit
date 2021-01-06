//
//  KKFishHook.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/4.
//

#import "KKFishHook.h"
#import "fishhook.h"
#import "ffi.h"
#import <objc/runtime.h>
#import <KernelKit/KKBlock.h>

int testFunc(char* a, int b) {
    return b + 1;
}

int testFunc1(char* a, test_t b) {
    return b.x + 1;
}

@interface KKContext()
@property(nonatomic, copy, readwrite) id replacement_function;
@property(nonatomic, readwrite) void* replaced_function;
@property(nonatomic, readwrite) NSMethodSignature* signature;
@end

@implementation KKContext

@end

static ffi_type *_kk_ffi_type(const char *c);
static void _kk_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *context);

static NSMutableDictionary* _kk_fish_hook_blocks = @{}.mutableCopy;
void kk_fish_hook(NSString* func, kk_replacement_function block) {
    if (!func.length || !block) return;
    
    // __NSStackBlock__ -> __NSStackBlock -> NSBlock
    if ([block isKindOfClass:NSClassFromString(@"__NSStackBlock")]) {
        NSLog(@"Hooking StackBlock causes a memory leak! I suggest you copy it first!");
    }
    
    KKContext* context = [[KKContext alloc] init];
    context.replacement_function = block;
    
    NSError* error;
    NSMethodSignature* signature = kk_block_method_signature(block, &error);
    context.signature = signature;
    
    // 构造参数类型列表
    size_t argc = signature.numberOfArguments;
    ffi_type **argTypes = (ffi_type **)calloc(argc, sizeof(ffi_type *));
    for (size_t i = 0; i < argc; ++i) {
        const char *argType = [signature getArgumentTypeAtIndex:i];
        ffi_type *arg_ffi_type = _kk_ffi_type(argType);
        NSCAssert(arg_ffi_type, @"can't find a ffi_type: %s", argType);
        argTypes[i] = arg_ffi_type;
    }
    
    // 返回值类型
    ffi_type *retType = _kk_ffi_type(signature.methodReturnType);
    
    // 生成 ffi_cfi 模版对象，保存函数参数个数、类型等信息，相当于一个函数原型
    ffi_cif *cif = (ffi_cif *)calloc(1, sizeof(ffi_cif));
    ffi_status ret = ffi_prep_cif(cif, FFI_DEFAULT_ABI, (UInt32)argc, retType, argTypes);
    if (ret != FFI_OK) {
        NSCAssert(NO, @"ffi_prep_cif failed: %d", ret);
        return;
    }
    
    // 生成新的 Function
    void *_kk_closure_function = NULL;
    ffi_closure *closure = (ffi_closure *)ffi_closure_alloc(sizeof(ffi_closure), (void **)&_kk_closure_function);
    ret = ffi_prep_closure_loc(closure, cif, _kk_ffi_closure_func, (__bridge_retained void *)context, _kk_closure_function);
    if (ret != FFI_OK) {
        NSCAssert(NO, @"ffi_prep_closure_loc failed: %d", ret);
        return;
    }
    
    void *(*replaced)(...) = nullptr;
    void *replacement = _kk_closure_function;
    
    rebind_symbols((struct rebinding[1]){
        func.UTF8String, replacement, (void**)&replaced
    }, 1);
    
    context.replaced_function = (void*)replaced;
}

static void _kk_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *userdata) {
    KKContext* context = (__bridge_transfer id)userdata;
    
    NSMethodSignature* signature = context.signature;
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:context.signature];
    if (signature.numberOfArguments > 1) {
        [invocation setArgument:(void *)&context atIndex:1];
    }
    
    // origin block invoke func arguments: block(self), ...
    // origin block invoke func arguments (x86 struct return): struct*, block(self), ...
    for (NSUInteger idx = 2; idx < signature.numberOfArguments; idx++) {
        [invocation setArgument:args[idx - 2] atIndex:idx];
    }
    
    [invocation setReturnValue:ret];
    [invocation retainArguments];
    
    [invocation invokeWithTarget:context.replacement_function];
    //ffi_call(cif, (void(*)(void))block->invoke, ret, args);
}


/**
 * BlockHook implementation
 * https://github.com/yulingtianxia/BlockHook
 */
#define SINT(type) do { \
    if (str[0] == @encode(type)[0]) { \
        if (sizeof(type) == 1) { \
            return &ffi_type_sint8; \
        } else if (sizeof(type) == 2) { \
            return &ffi_type_sint16; \
        } else if (sizeof(type) == 4) { \
            return &ffi_type_sint32; \
        } else if (sizeof(type) == 8) { \
            return &ffi_type_sint64; \
        } else { \
            NSLog(@"Unknown size for type %s", #type); \
            abort(); \
        } \
    } \
} while(0)

#define UINT(type) do { \
    if (str[0] == @encode(type)[0]) { \
        if (sizeof(type) == 1) { \
            return &ffi_type_uint8; \
        } else if (sizeof(type) == 2) { \
            return &ffi_type_uint16; \
        } else if (sizeof(type) == 4) { \
            return &ffi_type_uint32; \
        } else if (sizeof(type) == 8) { \
            return &ffi_type_uint64; \
        } else { \
            NSLog(@"Unknown size for type %s", #type); \
            abort(); \
        } \
    } \
} while(0)

#define INT(type) do { \
    SINT(type); \
    UINT(unsigned type); \
} while(0)

#define COND(type, name) do { \
    if (str[0] == @encode(type)[0]) { \
        return &ffi_type_ ## name; \
    } \
} while(0)

#define PTR(type) COND(type, pointer)

static ffi_type *_kk_ffi_struct_type(const char *str) {
//    NSUInteger size, align;
//    long length;
//    BHSizeAndAlignment(str, &size, &align, &length);
//    ffi_type *structType = [self _allocate:sizeof(*structType)];
//    structType->type = FFI_TYPE_STRUCT;
//
//    const char *temp = [[[NSString stringWithUTF8String:str] substringWithRange:NSMakeRange(0, length)] UTF8String];
//
//    // cut "struct="
//    while (temp && *temp && *temp != '=') {
//        temp++;
//    }
//    int elementCount = 0;
//    ffi_type **elements = [self _typesWithEncodeString:temp + 1 getCount:&elementCount startIndex:0 nullAtEnd:YES];
//    if (!elements) {
//        return nil;
//    }
//    structType->elements = elements;
//    return structType;
    return nil;
}

static ffi_type *_kk_ffi_type(const char *str) {
    SINT(_Bool);
    SINT(signed char);
    UINT(unsigned char);
    INT(short);
    INT(int);
    INT(long);
    INT(long long);
    
    PTR(id);
    PTR(Class);
    PTR(SEL);
    PTR(void *);
    PTR(char *);
    
    COND(float, float);
    COND(double, double);
    
    COND(void, void);
    
    // Ignore Method Encodings
    switch (*str) {
        case 'r':
        case 'R':
        case 'n':
        case 'N':
        case 'o':
        case 'O':
        case 'V':
            return _kk_ffi_type(str + 1);
    }
    
    // Struct Type Encodings
    if (*str == '{') {
        ffi_type *structType = _kk_ffi_struct_type(str);
        return structType;
    }
    
    NSLog(@"Unknown encode string %s", str);
    return NULL;
}
