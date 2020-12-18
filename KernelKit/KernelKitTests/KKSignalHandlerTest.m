//
//  KKSignalHandlerTest.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/16.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>

@interface KKSignalHandlerTest : XCTestCase

@end

@implementation KKSignalHandlerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [KKSignalHandler kk_register_signals_callback:^(kk_signal signal) {
        NSLog(@"crash happened");
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        //raise(SIGSEGV);
    }];
}

@end
