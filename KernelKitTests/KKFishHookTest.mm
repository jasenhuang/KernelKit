//
//  KKFishHookTest.m
//  KernelKitTests
//
//  Created by 黄栩生 on 2020/12/24.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>
#import <objc/runtime.h>

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
//    kk_fish_hook(@"testFunc", (kk_replacement_function)^int(KKContext *context, char* name, int age) {
//        int(*origin)(char*,int) = (int(*)(char*,int))context.replaced_function;
//        int sum = origin(name, age);
//        return sum;
//    });
//    testFunc("jasen", 2);
    
    kk_fish_hook(@"testFunc1", (kk_replacement_function)^int(KKContext *context, char* name, CGRect rect) {
        int(*origin)(char*,CGRect) = (int(*)(char*,CGRect))context.replaced_function;
        int sum = origin(name, rect);
        return sum;
    });
    testFunc1("jasen", CGRectMake(100, 0, 0, 0));
    
//    kk_fish_hook(@"printf", (kk_replacement_function)^(const char * format, ...){
//        NSLog(@"");
//    });
//    printf("%d, %s\n", 1, "hello");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
