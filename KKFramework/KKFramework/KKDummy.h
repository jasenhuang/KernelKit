//
//  KKDummy.h
//  KernelKit
//
//  Created by jasenhuang on 2021/1/7.
//

#import <Foundation/Foundation.h>

#if defined(__cplusplus)
#define KF_EXTERN extern "C" __attribute__((visibility("default")))
#define KF_EXTERN_C_BEGIN extern "C" {
#define KF_EXTERN_C_END }
#else
#define KF_EXTERN extern __attribute__((visibility("default")))
#define KF_EXTERN_C_BEGIN
#define KF_EXTERN_C_END
#endif

KF_EXTERN_C_BEGIN

struct test_t {
    int x;
    int y;
    int a;
    int b;
    int c;
};

int testFunc(char* a, int b);
int testFunc1(char* a, struct test_t b);
struct test_t testFunc2(int a);

KF_EXTERN_C_END
