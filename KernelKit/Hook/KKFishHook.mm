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

KK_EXTERN void ffi_types_free(ffi_type** types);

/**
 * free allocated ffi_type
 */
inline void ffi_type_free(ffi_type* type) {
    if (!type || type->type != FFI_TYPE_STRUCT) return ;
    ffi_types_free(type->elements);
    free(type);
}

/**
 * free allocated ffi_types with null end
 */
inline void ffi_types_free(ffi_type** types) {
    if (!types) return ;
    int index = 0;
    ffi_type* type = NULL;
    do {
        type = *(types + index++);
        ffi_type_free(type);
    } while(type != NULL);
    free(types);
}


@interface KKContext()
@property(nonatomic, copy, readwrite) id replacement_function;
@property(nonatomic, readwrite) void* replaced_function;
@property(nonatomic, readwrite) NSMethodSignature* signature;
@end

@implementation KKContext

@end

@interface KKToken()
@property(nonatomic, readwrite) ffi_cif *cif;
@property(nonatomic, readwrite) NSUInteger argc;
@property(nonatomic, readwrite) ffi_type **argTypes;
@property(nonatomic, readwrite) ffi_type *retType;
@property(nonatomic, readwrite) ffi_closure *closure;
@property(nonatomic, readwrite) NSString* name;
@property(nonatomic, readwrite) void* replaced;
@end

@implementation KKToken
- (void)restore {
    rebind_symbols((struct rebinding[1]){
        _name.UTF8String, _replaced, NULL
    }, 1);
}

- (void)dealloc
{
    free(_cif);_cif = NULL;
    ffi_types_free(_argTypes);_argTypes = NULL;
    ffi_type_free(_retType);_retType = NULL;
    ffi_closure_free(_closure);_closure = NULL;
}
@end

static ffi_type *_kk_ffi_type(const char *c);
static void _kk_ffi_closure_func(ffi_cif *cif, void *ret, void **args, void *context);

static NSMutableDictionary* _kk_fish_hook_blocks = @{}.mutableCopy;
KKToken* kk_fish_hook(NSString* func, kk_replacement_function block) {
    if (!func.length || !block) return nil;
    
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
    ffi_type **argTypes = (ffi_type **)calloc(argc + 1, sizeof(ffi_type *));
    for (size_t i = 0; i < argc; ++i) {
        const char *argType = [signature getArgumentTypeAtIndex:i];
        ffi_type *arg_ffi_type = _kk_ffi_type(argType);
        NSCAssert(arg_ffi_type, @"can't find a ffi_type: %s", argType);
        argTypes[i] = arg_ffi_type;
    }
    // null end
    argTypes[argc] = NULL;
    
    // 返回值类型
    ffi_type *retType = _kk_ffi_type(signature.methodReturnType);
    
    // 生成 ffi_cfi 模版对象，保存函数参数个数、类型等信息，相当于一个函数原型
    ffi_cif *cif = (ffi_cif *)calloc(1, sizeof(ffi_cif));
    ffi_status ret = ffi_prep_cif(cif, FFI_DEFAULT_ABI, (UInt32)argc, retType, argTypes);
    if (ret != FFI_OK) {
        NSCAssert(NO, @"ffi_prep_cif failed: %d", ret);
        return nil;
    }
    
    // 生成新的 Function
    void *_kk_closure_function = NULL;
    ffi_closure *closure = (ffi_closure *)ffi_closure_alloc(sizeof(ffi_closure), (void **)&_kk_closure_function);
    ret = ffi_prep_closure_loc(closure, cif, _kk_ffi_closure_func, (__bridge_retained void *)context, _kk_closure_function);
    if (ret != FFI_OK) {
        NSCAssert(NO, @"ffi_prep_closure_loc failed: %d", ret);
        return nil;
    }
    
    void *(*replaced)(...) = nullptr;
    void *replacement = _kk_closure_function;
    
    rebind_symbols((struct rebinding[1]){
        func.UTF8String, replacement, (void**)&replaced
    }, 1);
    
    context.replaced_function = (void*)replaced;
    
    // token 内存管理
    KKToken* token = [[KKToken alloc] init];
    token.cif = cif;
    token.closure = closure;
    token.argTypes = argTypes;
    token.retType = retType;
    token.argc = argc;
    token.replaced = (void*)replaced;
    token.name = func;
    _kk_fish_hook_blocks[func] = token;
    
    return token;
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
    //[invocation retainArguments];//TODO
    
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

static ffi_type *_kk_ffi_struct_type(const char *str);

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

static const char *_kk_size_alignment(const char *str, NSUInteger *sizep, NSUInteger *alignp, long *lenp) {
    const char *out = NSGetSizeAndAlignment(str, sizep, alignp);
    if (lenp) {
        *lenp = out - str;
    }
    while(*out == '}') {
        out++;
    }
    while(isdigit(*out)) {
        out++;
    }
    return out;
}

static int _kk_ffi_type_count(const char *str) {
    int count = 0;
    while(str && *str) {
        str = _kk_size_alignment(str, NULL, NULL, NULL);
        count++;
    }
    return count;
}

static ffi_type **_kk_ffi_types(const char* str, int* count) {
    *count = _kk_ffi_type_count(str);
    ffi_type **argTypes = (ffi_type **)calloc(*count + 1, sizeof(ffi_type));
    
    int i = 0;
    while (str && *str && i < *count) {
        ffi_type *argType = _kk_ffi_type(str);
        if (argType){
            argTypes[i] = argType;
        }else{
            *count = -1;
            return NULL;
        }
        const char *next = _kk_size_alignment(str, NULL, NULL, NULL);
        str = next;
        ++i;
    }
    
    argTypes[*count] = NULL; // null end
    return argTypes;
}

static ffi_type *_kk_ffi_struct_type(const char *str) {
    NSUInteger size, align;
    long length;
    _kk_size_alignment(str, &size, &align, &length);
    ffi_type *structType = (ffi_type *)calloc(1, sizeof(ffi_type));
    structType->type = FFI_TYPE_STRUCT;
    
    char buf[length + 1]; memset(buf, 0, sizeof(buf));
    stpncpy(buf, str, length);
    char* temp = &buf[0];
    // cut "struct="
    while (*temp && *temp != '=') {
        temp++;
    }
    int count = 0;
    ffi_type **elements = _kk_ffi_types(temp + 1, &count);
    if (!elements)  return NULL;
    
    structType->elements = elements;
    return structType;
}
