//
//  KKAutoreleaseTest.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/16.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>
#include <malloc/malloc.h>

@interface KKAutoreleaseTest : XCTestCase

@end

@implementation KKAutoreleaseTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
//    for (NSInteger i = 0 ; i < 1000000; ++i) {
//        malloc_zone_memalign(malloc_default_zone(), 4096, 4096);
//    }
//    sleep(100);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
