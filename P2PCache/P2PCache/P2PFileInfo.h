//
//  P2PFileInfo.h
//  P2PCache
//
//  Created by Alex Krebiehl on 3/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PFileInfo;

/** Provides updates about the file's information */
@protocol P2PFileInfoDelegate <NSObject>

/** Called when the file's cached state is changed.  Will be called on the main thread.
 
 @param fileInfo The object containing the file's information
 @param chunksOnDisk The number of chunks now available on disk
 */
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksOnDisk:(NSUInteger)chunksOnDisk;

/** Called when the file availability from peers changes.  Will be called on the main thread.
 
 @param fileInfo The object containing the file's information
 @param chunksAvailable The number of chunks now available from peers
 */
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksAvailableFromPeers:(NSUInteger)chunksAvailable;

@end

@interface P2PFileInfo : NSObject

@property (weak, nonatomic) id<P2PFileInfoDelegate> delegate;
@property (copy, readonly, nonatomic) NSString *filename;
@property (copy, readonly, nonatomic) NSString *fileId;
@property (readonly, nonatomic) NSSet *chunksAvailable;
@property (readonly, nonatomic) NSSet *chunksOnDisk;
@property (readonly, nonatomic) NSUInteger totalChunks;
@property (readonly, nonatomic) NSUInteger totalFileSize;

- (id)initWithFileName:(NSString *)fileName fileId:(NSString *)fileId chunksOnDisk:(NSArray *)chunksOnDisk totalChunks:(NSUInteger)totalChunks totalFileSize:(NSUInteger)totalFileSize;

- (id)initWithFileId:(NSString *)fileId info:(NSDictionary *)plist chunksOnDisk:(NSArray *)chunksOnDisk;

- (NSDictionary *)toDictionary;


- (void)chunkWasAddedToDisk:(NSNumber *)chunkId;
- (void)chunkBecameAvailable:(NSNumber *)chunkId;

@end
