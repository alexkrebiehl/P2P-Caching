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

/** The delegate will recieve information about changes to the file info object */
@property (weak, nonatomic) id<P2PFileInfoDelegate> delegate;

/**  Name of the file.  May be nil */
@property (copy, nonatomic) NSString *filename;

/** File identifier.  May be nil if the @c filename could not be matched to an ID */
@property (copy, nonatomic) NSString *fileId;

/** A set of which chunks IDs are available.  The count of an object in the set is the number of peers it is available from */
@property (readonly, nonatomic) NSCountedSet *chunksAvailable;

/** The chunks IDs that are locally cached */
@property (readonly, nonatomic) NSSet *chunksOnDisk;

/** The total number of chunks we are expecting for this file */
@property (readonly, nonatomic) NSUInteger totalChunks;

/** The total size on disk if we have the entire file */
@property (nonatomic) NSUInteger totalFileSize;


/** This should only ever be initialized by the FileManager! */
- (id)initWithFileName:(NSString *)fileName fileId:(NSString *)fileId chunksOnDisk:(NSSet *)chunksOnDisk totalFileSize:(NSUInteger)totalFileSize;


/** This should only ever be initialized by the FileManager! */
- (id)initWithFileId:(NSString *)fileId info:(NSDictionary *)plist chunksOnDisk:(NSSet *)chunksOnDisk;


/** Serializes the file info to a @c NSDictionary in order to be saved to disk
 
 @return A dictionary representation of the @c P2PFileInfo object that can be saved as a JSON object
 */
- (NSDictionary *)toDictionary;


/** The @c P2PFileManager should call this method if a file is completely deleted from the cache.
 */
- (void)fileWasDeleted;


/** The @c P2PFileManager should call this when it writes a chunk of this file's data to disk.
 
 @param chunkId The @c chunkId that was written to disk
 */
- (void)chunkWasAddedToDisk:(NSNumber *)chunkId;


/** The @c P2PFileManager should call this when it removes a chunk of this file's data from disk.
 
 @param chunkId The @c chunkId that was removed from disk
 */
- (void)chunkWasRemovedFromDisk:(NSNumber *)chunkId;


/** A @c P2PFileRequest object should call this method as it recieves @c P2PPeerFileAvailabilityResponses in order to update the chunks currently available on this file
 
 @param multipleChunkIds A set of @c chunkIds that have become available from a node
 */
- (void)chunksBecameAvailable:(NSSet *)multipleChunkIds;


/** A @c P2PFileRequest object should call this method as nodes disconnect from the network, making their @c P2PPeerFileAvailabilityResponses invalid.
 
 @param unavailableChunks A set of chunks that are no longer available from a node
 */
- (void)chunkBecameUnavailable:(NSSet *)unavailableChunks;

@end
