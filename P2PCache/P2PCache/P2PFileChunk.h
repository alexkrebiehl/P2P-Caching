//
//  P2PFileChunk.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

enum
{
    /** Default file chunk size */
    P2PFileChunkDefaultSize = 64 * 1024     // 64k chunks
};

@interface P2PFileChunk : P2PTransmittableObject

/** The name of the file this chunk is for */
@property (nonatomic, readonly, copy) NSString *fileName;

/** File identifier that this chunk belongs to */
@property (nonatomic, readonly, copy) NSString *fileId;

/** How big the file is after all of the chunks have been assembled */
@property (nonatomic, readonly) NSUInteger totalFileSize;

/** The location of this chunk within the file */
@property (nonatomic, readonly) NSUInteger chunkId;

/** Data for this chunk of the file */
@property (nonatomic, readonly) NSData *dataBlock;

/** Creates a new file chunk object that is transmittable to peers
 
 @param data Data for this chunk of the file
 @param chunkId The location of this chunk within the file
 @param fileId File identifier that this chunk belongs to
 @param filename The name of the file this chunk is for
 @param totalSize How big the file is after all of the chunks have been assembled
 @return A new file chunk object
 */
- (id)initWithData:(NSData *)data chunkId:(NSUInteger)chunkId fileId:(NSString *)fileId fileName:(NSString *)filename totalFileSize:(NSUInteger)totalSize;



@end
