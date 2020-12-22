//
//  KKDynamicLinkerTest.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/16.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>

@interface KKDynamicLinkerTest : XCTestCase

@end

@implementation KKDynamicLinkerTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSLog(@"%@", [KKDynamicLinker kk_get_loaded_mach_images]);
    kk_register_image_add_callback(^(const struct mach_header * _Nonnull header, intptr_t slide) {
        //NSLog(@"%p", header);
    });
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
