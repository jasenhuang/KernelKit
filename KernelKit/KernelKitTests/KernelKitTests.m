//
//  KernelKitTests.m
//  KernelKitTests
//
//  Created by jasenhuang on 2020/12/3.
//

#import <XCTest/XCTest.h>
#import <KernelKit/KernelKit.h>

@interface KernelKitTests : XCTestCase
@property(nonatomic) KKMemoryMappingHandler* handler;
@property(nonatomic) NSString* docPath;
@end

@implementation KernelKitTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, NO).firstObject;
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    self.handler = [KKMemoryMapping memoryMapping:[NSURL fileURLWithPath:[self.docPath stringByAppendingPathComponent:@"file"]]
                                          options:@{}
                                            error:nil];
    [self.handler write:[@"hello world!" dataUsingEncoding:NSUTF8StringEncoding] offset:0];
    
    NSData* data = [self.handler readAtOffset:5 length:5];
    NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [KKMemoryMapping memoryUnmapping:self.handler error:nil];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
