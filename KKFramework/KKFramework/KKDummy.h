//
//  KKDummy.h
//  KernelKit
//
//  Created by jasenhuang on 2021/1/7.
//

#import <Foundation/Foundation.h>

extern "C" {

struct test_t {
    int x;
    int y;
};

int testFunc(char* a, int b);
int testFunc1(char* a, struct test_t b);

}
