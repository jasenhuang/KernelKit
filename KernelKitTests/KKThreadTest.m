//
//  KKThreadTest.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/14.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>

@interface KKThreadTest : XCTestCase
@property(nonatomic) NSThread* thread;
@end

@implementation KKThreadTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.thread =
    [[NSThread alloc] initWithBlock:^{
        while (true) {
            NSArray* threads = kk_all_threads();
            for (KKThread* thread in threads) {
                NSLog(@"%@", thread.threadInfos);
            }
            break;
        }
    }];
    [self.thread setName:@"me.jasen.KernelKit.KKThread"];
    [self.thread start];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
