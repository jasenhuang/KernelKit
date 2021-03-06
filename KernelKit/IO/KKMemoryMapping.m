//
//  KKMemoryMapping.m
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import "KKMemoryMapping.h"
#import "KKMacros.h"
#import <sys/types.h>
#import <sys/mman.h>
#import <sys/stat.h>
#import <err.h>
#import <fcntl.h>

NSString* const KKMemoryMappingDomain = @"me.jasen.KenelKit.KKMemoryMapping";

void _kk_mem_map_error(NSError** error, int code, id msg) {
    if (error){
        *error = [NSError errorWithDomain:KKMemoryMappingDomain
                                     code:code
                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
    }
}

@interface KKMemoryMappingHandler()
@property(nonatomic, readwrite) NSURL* fileURL;
@property(nonatomic, copy, readwrite) NSDictionary* options;
#if DEBUG
@property(nonatomic) int fd;
#endif
@property(nonatomic, readwrite) void* pointer;
@property(nonatomic, readwrite) NSRange fileRange;
@property(nonatomic, readwrite) NSUInteger fileSize;
@end

@implementation KKMemoryMappingHandler

- (instancetype)initWithFileURL:(NSURL*)fileURL options:(NSDictionary*)options {
    self = [self init];
    if (self) {
        _options = options;
        _fileURL = fileURL;
    }
    return self;
}

- (NSData*)readData:(NSRange)range {
    if (!_pointer) return nil;
    
    range.location += self.fileRange.location; /* 位置转换 */
    
    size_t length = range.length;
    
    /* trim length */
    if (NSMaxRange(range) > NSMaxRange(self.fileRange)){
        length = NSMaxRange(self.fileRange) - range.location;
    }
    
    /* 读取数据 */
    char buff[length];
    memcpy(buff, _pointer + range.location, range.length);
    
    return [[NSData alloc] initWithBytes:buff length:length];
}

- (BOOL)writeData:(NSData*)data offset:(NSUInteger)offset {
    if (!_pointer) return NO;
    
    offset += self.fileRange.location; /* 位置转换 */
    
    if (!NSLocationInRange(offset, self.fileRange)) return NO;
    
    /* 自动扩容 */
    if (offset + data.length > self.fileSize
        && ![self truncateFileSize:offset + data.length]) {
        return NO;
    }
    
    /* 写入数据 */
    memcpy(_pointer, data.bytes, data.length);
    
    return YES;
}

- (BOOL)appendData:(NSData*)data {
    if (!_pointer) return NO;
    
    /* 自动扩容 */
    size_t length = self.fileSize + data.length;
    if (![self truncateFileSize:length]){
        return NO;
    }
    
    /* 写入数据 */
    memcpy(_pointer, data.bytes, data.length);
    
    return YES;
}

- (BOOL)truncateFileSize:(NSUInteger)length {
    if (!_pointer) return NO;
    
    NSError* error;
    if (!kk_munmap_handler(self, &error)){
        return NO;
    };
    
    if (truncate(self.fileURL.path.UTF8String, length)) {
        return NO;
    }
    
    if (!kk_mmap_handler(self, &error)){
        return NO;
    }
    
    return YES;
}

- (void)dealloc{
#if DEBUG
    close(self.fd);
#endif
    kk_munmap_handler(self, nil);
}

@end


KKMemoryMappingHandler* kk_mmap(NSURL* fileURL, NSDictionary* options, NSError** error) {
    KKMemoryMappingHandler* handler = [[KKMemoryMappingHandler alloc] initWithFileURL:fileURL options:options];
    if (!kk_mmap_handler(handler, error)){
        return nil;
    }
    return handler;
}

bool kk_mmap_handler(KKMemoryMappingHandler* handler, NSError** error) {
    if (!handler.fileURL.isFileURL || !handler.fileURL.path.length) {
        _kk_mem_map_error(error, -1, @"fileURL is empty");
        return NO;
    }
    /* 打开文件 */
    int fd = open(handler.fileURL.path.UTF8String, O_RDWR|O_CREAT, S_IREAD|S_IWRITE);
    if (fd < 0){
        _kk_mem_map_error(error, errno, @"open file error");
        return NO;
    }
    NSRange range = [handler.options[@"range"] rangeValue];
    size_t offset = range.location;
    
    /* 获取文件的属性 */
    struct stat fileStat;
    if (fstat(fd, &fileStat) < 0) {
        _kk_mem_map_error(error, errno, @"open stat error");
        return NO;
    }
    size_t length = range.length ? : fileStat.st_size;
    length = length ? : PAGE_SIZE;
    
    int prot = [handler.options[@"prot"] intValue];
    prot = prot ? : PROT_READ|PROT_WRITE;
    
    int flags = [handler.options[@"flags"] intValue];
    flags = flags ? : MAP_SHARED;
    
    /* 将文件映射至进程的地址空间 */
    void* pointer = mmap(NULL, length, prot, flags, fd, offset);
    if (!pointer || pointer == MAP_FAILED) {
        _kk_mem_map_error(error, errno, @"mmap error");
        return NO;
    }

    handler.pointer = pointer;
    handler.fileRange = NSMakeRange(offset, length);
    handler.fileSize = fileStat.st_size;
#if DEBUG
    handler.fd = fd;
#else
    /* 文件已在内存, 关闭文件也可以操纵内存 */
    close(fd);
#endif
    return YES;
}

bool kk_msync_handler(KKMemoryMappingHandler* handler, NSError** error) {
    if (!handler.pointer) return NO;
    
    int code = msync(handler.pointer, handler.fileRange.length, MS_ASYNC);
    if (code) {
        _kk_mem_map_error(error, errno, @"mmap sync error");
    }
    return !code;
}

bool kk_munmap_handler(KKMemoryMappingHandler* handler, NSError** error) {
    if (!handler.pointer) return NO;
    int code = munmap(handler.pointer, handler.fileRange.length);
    if (code) {
        _kk_mem_map_error(error, errno, @"munmap error");
    }
    handler.pointer = NULL;
#if DEBUG
    close(handler.fd);
#endif
    return !code;
}
