//
//  KKMemoryMapping.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKMemoryMapping.h"
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <err.h>
#include <fcntl.h>

NSString* const KKMemoryMappingDomain = @"me.jasen.KenelKit.KKMemoryMapping";

@class KKMemoryMapping;

@interface KKMemoryMappingHandler()
@property(nonatomic) void* pointer;
@property(nonatomic) NSRange range;
@end

@implementation KKMemoryMappingHandler

+ (KKMemoryMappingHandler*)handlerForURL:(NSURL*)fileURL options:(NSDictionary*)options {
    return [KKMemoryMapping mmap:fileURL
                         options:options
                           error:nil];
}

- (instancetype)initWithPointer:(void*)pointer
{
    self = [self init];
    if (self) {
        _pointer = pointer;
    }
    return self;
}

- (NSData*)readAtOffset:(NSUInteger)offset length:(NSUInteger)length {
    if (!_pointer) return nil;
    
    char buff[length];
    memcpy(buff, _pointer + offset, length);
    
    return [[NSData alloc] initWithBytes:buff length:length];
}

- (BOOL)write:(NSData*)data offset:(NSUInteger)offset {
    if (!_pointer) return NO;
    
    
    
    return YES;
}

@end

@implementation KKMemoryMapping

+ (KKMemoryMappingHandler*)mmap:(NSURL*)fileURL options:(NSDictionary*)options error:(NSError**)error {
    if (!fileURL.isFileURL || !fileURL.absoluteString.length) {
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:-1
                                 userInfo:@{@"msg":@"fileURL is empty"}];
        return nil;
    }
    /* 打开文件 */
    int fd = open(fileURL.absoluteString.UTF8String, O_RDWR|O_CREAT);
    if (fd < 0){
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:-1
                                 userInfo:@{@"msg":@"open file error"}];
        return nil;
    }
    
    NSUInteger offset = [options[@"offset"] integerValue];
    NSUInteger size = [options[@"size"] integerValue];
    
    /* 获取文件的属性 */
    struct stat fileStat;
    if (fstat(fd, &fileStat) < 0) {
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:-1
                                 userInfo:@{@"msg":@"file stat error"}];
        return nil;
    }
    size = size ? : fileStat.st_size;
    size = size ? : PAGE_SIZE;
    
    int prot = [options[@"prot"] intValue];
    prot = prot ? : PROT_READ|PROT_WRITE;
    
    int flags = [options[@"flags"] intValue];
    flags = flags ? : MAP_SHARED;
    
    /* 将文件映射至进程的地址空间 */
    void* pointer = mmap(NULL, size, prot, flags, fd, offset);
    if (!pointer || pointer == MAP_FAILED) {
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:-1
                                 userInfo:@{@"msg":@"mmap error"}];
        return nil;
    }
    
    /* 文件已在内存, 关闭文件也可以操纵内存 */
    close(fd);
    
    KKMemoryMappingHandler* handler = [[KKMemoryMappingHandler alloc] initWithPointer:pointer];
    handler.range = NSMakeRange(offset, size);
    return handler;
}

+ (BOOL)msync:(KKMemoryMappingHandler*)handler error:(NSError**)error {
    if (!handler.pointer) return NO;
    
    int code = msync(handler.pointer, handler.range.length, MS_ASYNC);
    if (code) {
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:code
                                 userInfo:@{@"msg":@"mmap sync error"}];
    }
    return NO;
}

+ (BOOL)munmap:(KKMemoryMappingHandler*)handler error:(NSError**)error {
    if (!handler.pointer) return NO;
    
    int code = munmap(handler.pointer, handler.range.length);
    if (code) {
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:code
                                 userInfo:@{@"msg":@"munmap error"}];
    }
    return !code;
}

@end
