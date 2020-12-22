//
//  KKMemoryMapping.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <KernelKit/KKMacros.h>

typedef NS_OPTIONS(NSUInteger, KK_MEM_PROT_MODE) {
    KK_MEM_PROT_NONE        = 0,        /* [MC2] no permissions */
    KK_MEM_PROT_READ        = 1 << 0,   /* [MC2] pages can be read */
    KK_MEM_PROT_WRITE       = 1 << 1,   /* [MC2] pages can be written */
    KK_MEM_PROT_EXEC        = 1 << 2,   /* [MC2] pages can be executed */
};

typedef NS_OPTIONS(NSUInteger, KK_MEM_SHARE_TYPE) {
    KK_MEM_SHARE_NONE       = 0,
    KK_MEM_SHARE_SHARED     = 1 << 0,   /* [MF|SHM] share changes (default) */
    KK_MEM_SHARE_PRIVATE    = 1 << 1,   /* [MF|SHM] changes are private */
};

typedef NS_OPTIONS(NSUInteger, KK_MEM_MAP_TYPE) {
    KK_MEM_MAP_FILE         = 0,        /* map from file (default) */
    KK_MEM_MAP_ANON         = 1 << 11,  /* allocated from memory, swap space */
};

extern NSString* const KKMemoryMappingDomain;

@class KKMemoryMappingHandler;

/**
 * mmap file at fileURL and return handler
 * options:
 *  offset -> mapping file offset
 *  size -> mapping length (default: file size or PAGE_SIZE)
 *  prot -> KK_MEM_PROT_MODE (default: KK_MEM_PROT_READ | KK_MEM_PROT_WRITE)
 *  flags -> KK_MEM_SHARE_TYPE | KK_MEM_MAP_TYPE (default: KK_MEM_SHARE_SHARED)
 *
 */
KK_EXTERN_C_BEGIN

KKMemoryMappingHandler* kk_mmap(NSURL* fileURL, NSDictionary* options, NSError** error);

/**
 * remmap
 */
bool kk_mmap_handler(KKMemoryMappingHandler* handler, NSError** error);

/**
 * msync
 */
bool kk_msync_handler(KKMemoryMappingHandler* handler, NSError** error);

/**
 * munmap
 */
bool kk_munmap_handler(KKMemoryMappingHandler* handler, NSError** error);

KK_EXTERN_C_END


@interface KKMemoryMappingHandler : NSObject
@property(nonatomic, readonly) NSURL* fileURL;
@property(nonatomic, copy, readonly) NSDictionary* options;

@property(nonatomic, readonly) void* pointer;           //mapping memory address;
@property(nonatomic, readonly) NSRange fileRange;       //mapping file range
@property(nonatomic, readonly) NSUInteger fileSize;     //current file size

- (instancetype)initWithFileURL:(NSURL*)fileURL options:(NSDictionary*)options;

/**
 *  read data with memory range
 */
- (NSData*)readData:(NSRange)range;

/**
 * write data at memory offset
 * extend file automatically
 */
- (BOOL)writeData:(NSData*)data offset:(NSUInteger)offset;

/**
 * append data
 * extend file automatically
 */
- (BOOL)appendData:(NSData*)data;

@end
