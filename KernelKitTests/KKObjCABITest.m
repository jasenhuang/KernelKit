//
//  KKObjCABITest.m
//  KernelKitTests
//
//  Created by 黄栩生 on 2020/12/31.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KKBlock.h>
#import <objc/runtime.h>

@interface KKObjCABITest : XCTestCase

@end

@implementation KKObjCABITest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    IMP imp = imp_implementationWithBlock(^(int a, int b, int c, int d){
        NSLog(@"%@,%@,%@,%@", @(a), @(b), @(c), @(d));
    });
    ((void(*)(int, ...))imp)(1, NULL, 3, 4);
    NSMethodSignature* signature =
    kk_block_method_signature(^id(NSString* name, NSInteger age){
        return nil;
    }, nil);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
