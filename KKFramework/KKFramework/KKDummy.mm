//
//  KKDummy.m
//  KernelKit
//
//  Created by jasenhuang on 2021/1/7.
//

#import "KKDummy.h"

int testFunc(char* a, int b) {
    return b + 1;
}

int testFunc1(char* a, struct test_t b) {
    return b.x + 1;
}

struct test_t testFunc2(int a) {
    struct test_t t;
    t.x = a;
    t.y = 0;
    return t;
}
