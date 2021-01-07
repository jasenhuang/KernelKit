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
