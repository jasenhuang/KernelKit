//
//  KKMemoryMapping.h
//  KernelKit
//
//  Created by jasenhuang on 2020/12/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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

@interface KKMemoryMappingHandler : NSObject

/**
 *  create memory mapping handler
 */
+ (KKMemoryMappingHandler*)handlerForURL:(NSURL*)fileURL options:(NSDictionary*)options;

/**
 *  read data at offset with length
 *  offset -> file offset
 */
- (NSData*)readAtOffset:(NSUInteger)offet length:(NSUInteger)length;

/**
 * write data at offset
 * offset -> file offset
 * extend file automatically
 */
- (BOOL)write:(NSData*)data offset:(NSUInteger)offset;

@end

@interface KKMemoryMapping : NSObject

/**
 * mmap file at fileURL and return handler
 * options:
 *  offset -> mapping file offset
 *  size -> mapping length (default: file size or PAGE_SIZE)
 *  prot -> KK_MEM_PROT_MODE (default: KK_MEM_PROT_READ | KK_MEM_PROT_WRITE)
 *  flags -> KK_MEM_SHARE_TYPE | KK_MEM_MAP_TYPE (default: KK_MEM_SHARE_SHARED)
 *
 */
+ (KKMemoryMappingHandler*)mmap:(NSURL*)fileURL options:(NSDictionary*)options error:(NSError**)error;

/**
 * msync
 */
+ (BOOL)msync:(KKMemoryMappingHandler*)handler error:(NSError**)error;

/**
 * munmap
 */
+ (BOOL)munmap:(KKMemoryMappingHandler*)handler error:(NSError**)error;

@end

NS_ASSUME_NONNULL_END
