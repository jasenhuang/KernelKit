//
//  KKFishHook.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/4.
//

#import "KKFishHook.h"
#import "fishhook.h"
#import <objc/runtime.h>

static void _kk_binding_func(struct _kk_binding_imp *_binding);

struct _kk_binding_imp {
    kk_replaced_function replaced;
    IMP replacement;
    void *FuncPtr;
    _kk_binding_imp(kk_replaced_function replaced, IMP replacement)
    :FuncPtr((void*)_kk_binding_func),
    replaced(replaced),
    replacement(replacement) {}
};

static void _kk_binding_func(struct _kk_binding_imp *_binding) {
    if (_binding && _binding->replacement){
        ((void(*)(...))_binding->replacement)(_binding->replaced, NULL);
    }
}

void kk_fish_hook(NSString* func, void*(^block)(void*(*)(...), ...)) {
    if (!func.length || !block) return;
    
    NSMethodSignature* signature;
    
    void *(*replaced)(...) = nullptr;
    void *replacement = nullptr;
    
    _kk_binding_imp* _bindingPtr = (_kk_binding_imp*)malloc(sizeof(_kk_binding_imp));
    _kk_binding_imp _binding = _kk_binding_imp(replaced, imp_implementationWithBlock(block));
    memcpy(_bindingPtr, &_binding, sizeof(_kk_binding_imp));
    replacement = _bindingPtr->FuncPtr;
    
    rebind_symbols((struct rebinding[1]){
        func.UTF8String, replacement, (void**)&replaced
    }, 1);
}
