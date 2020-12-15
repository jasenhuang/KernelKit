//
//  KKMacros.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/14.
//

#if defined(__cplusplus)
#define KK_EXTERN extern "C" __attribute__((visibility("default")))
#define KK_EXTERN_C_BEGIN extern "C" {
#define KK_EXTERN_C_END }
#else
#define KK_EXTERN extern __attribute__((visibility("default")))
#define KK_EXTERN_C_BEGIN
#define KK_EXTERN_C_END
#endif

/* Keys 40-49 for Objective-C runtime usage */
#define __PTK_FRAMEWORK_OBJC_KEY0    40
#define __PTK_FRAMEWORK_OBJC_KEY1    41
#define __PTK_FRAMEWORK_OBJC_KEY2    42
#define __PTK_FRAMEWORK_OBJC_KEY3    43
#define __PTK_FRAMEWORK_OBJC_KEY4    44
#define __PTK_FRAMEWORK_OBJC_KEY5    45
#define __PTK_FRAMEWORK_OBJC_KEY6    46
#define __PTK_FRAMEWORK_OBJC_KEY7    47
#define __PTK_FRAMEWORK_OBJC_KEY8    48
#define __PTK_FRAMEWORK_OBJC_KEY9    49

typedef pthread_key_t tls_key_t;
/* ObjC runtime tls key */
#define TLS_DIRECT_KEY        ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY0)
#define SYNC_DATA_DIRECT_KEY  ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY1)
#define SYNC_COUNT_DIRECT_KEY ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY2)
#define AUTORELEASE_POOL_KEY  ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY3)
#define RETURN_DISPOSITION_KEY ((tls_key_t)__PTK_FRAMEWORK_OBJC_KEY4)

#import "KKLog.h"
