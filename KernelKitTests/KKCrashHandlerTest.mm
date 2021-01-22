//
//  KKSignalHandlerTest.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/16.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>
#include <exception>

@interface KKCrashHandlerTest : XCTestCase

@end

@implementation KKCrashHandlerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    kk_register_signals_callback(^(kk_signal signal) {
        NSLog(@"signal crash happened");
    });
    
    // hint: close debug executable and uncomment below
    //raise(SIGSEGV);
    
    kk_register_exception_callback(^(NSException * exception) {
        NSLog(@"exception crash happened");
    });
    // hint: NSException not work in xctest, see KKSample
    //[@{}.mutableCopy setObject:nil forKey:@""];
    
    kk_register_termination_callback(^(KKTermination * termination) {
        NSLog(@"c++ crash happened");
    });
    // hint: c++ exception not work in xctest, see KKSample
    //throw "Division by zero condition!";
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
