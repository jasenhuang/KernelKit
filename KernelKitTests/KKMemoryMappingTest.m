//
//  KKMemoryMappingTest.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/4.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>

@interface KKMemoryMappingTest : XCTestCase
@property(nonatomic) KKMemoryMappingHandler* handler;
@property(nonatomic) NSString* docPath;
@end

@implementation KKMemoryMappingTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSURL* fileURL = [NSURL fileURLWithPath:
                      [self.docPath stringByAppendingPathComponent:@"file"]];
    
    self.handler = kk_mmap(fileURL, @{}, nil);
    [self.handler writeData:[@"hello world!" dataUsingEncoding:NSUTF8StringEncoding] offset:0];
    
    NSData* data = [self.handler readData:NSMakeRange(5, 5)];
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    kk_munmap_handler(self.handler, nil);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
