//
//  KKSwizzle.h
//  KernelKit
//
//  Created by 黄栩生 on 2020/12/27.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>
#import <objc/runtime.h>

KK_EXTERN_C_BEGIN

void kk_exchange_implementation(Class cls, SEL originSelector, SEL newSelector);

void kk_override_implementation(Class cls, SEL targetSelector);


KK_EXTERN_C_END
