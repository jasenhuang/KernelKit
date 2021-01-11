//
//  KKFishHookTest.m
//  KernelKitTests
//
//  Created by 黄栩生 on 2020/12/24.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>
#import <objc/runtime.h>
#import <KKFramework/KKFramework.h>

@interface KKFishHookTest : XCTestCase

@end

@implementation KKFishHookTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    // hook function
    kk_fish_hook(@"testFunc", (kk_replacement_function)^int(KKContext *context, char* name, int age) {
        int(*origin)(char*,int) = (int(*)(char*,int))context.replaced_function;
        int sum = origin(name, age);
        return sum;
    });
    testFunc((char*)"jasen", 2);
    
    // hook function with struct
    kk_fish_hook(@"testFunc1", (kk_replacement_function)^int(KKContext *context, char* name, struct test_t rect) {
        int(*origin)(char*,struct test_t) = (int(*)(char*,struct test_t))context.replaced_function;
        int sum = origin(name, rect);
        return sum;
    });
    struct test_t t;
    t.x = 100;
    testFunc1((char*)"jasen", t);
    
    /**
     * hook function with var_list
     *
     */
    kk_fish_hook(@"printf", (kk_replacement_function)^int(KKContext *context, char * format, KKTypeList){
        int(*origin)(char*,...) = (int(*)(char*,...))context.replaced_function;
        origin(format, KKVarList);
        return 0;
    });
    printf("%d, %s, %s\n", 1, "hello", "world");
    
    kk_fish_hook(@"testFunc2", (kk_replacement_function)^struct test_t(KKContext *context, int a){
        struct test_t(*origin)(int) = (struct test_t(*)(int))context.replaced_function;
        struct test_t ret = origin(a);
        NSLog(@"{%@, %@}", @(ret.x), @(ret.y));
        return ret;
    });
    /**
     * hook async
     */
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Wait for block invoke."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        struct test_t ret = testFunc2(1);
        NSLog(@"{%@, %@}", @(ret.x), @(ret.y));
        [expectation fulfill];
    });
    [self waitForExpectations:@[expectation] timeout:30];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
