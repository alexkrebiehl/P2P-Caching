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

/** Called when the file info object has updated the total number of file chunks
 
 @param fileInfo The object containing the file's information
 @param totalChunks The total number of chunks needed to fully cache the file
 */
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateTotalChunks:(NSUInteger)totalChunks;

/** Called when the file info object has updated the filename or fileId
 
 @param fileInfo The object containing the file's information
 @param fileId The new Id of the file.  May be nil
 @param filename The new name of the file.  May be nil
 */
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateFileId:(NSString *)fileId filename:(NSString *)filename;

@end

@interface P2PFileInfo : NSObject

@property (weak, nonatomic) id<P2PFileInfoDelegate> delegate;
@property (copy, nonatomic) NSString *filename;
@property (copy, nonatomic) NSString *fileId;
@property (readonly, nonatomic) NSSet *chunksAvailable;
@property (readonly, nonatomic) NSSet *chunksOnDisk;
@property (readonly, nonatomic) NSUInteger totalChunks;
@property (nonatomic) NSUInteger totalFileSize;


/** This should only ever be initialized by the FileManager! */
- (id)initWithFileName:(NSString *)fileName fileId:(NSString *)fileId chunksOnDisk:(NSArray *)chunksOnDisk totalFileSize:(NSUInteger)totalFileSize;

/** This should only ever be initialized by the FileManager! */
- (id)initWithFileId:(NSString *)fileId info:(NSDictionary *)plist chunksOnDisk:(NSArray *)chunksOnDisk;

- (NSDictionary *)toDictionary;


- (void)chunkWasAddedToDisk:(NSNumber *)chunkId;
- (void)chunkBecameAvailable:(NSNumber *)chunkId;
- (void)chunksBecameAvailable:(NSArray *)multipleChunkIds;

@end
