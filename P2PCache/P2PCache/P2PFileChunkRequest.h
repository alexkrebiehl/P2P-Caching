//
//  P2PFileChunkRequest.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/13/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PFileChunkRequest, P2PFileChunk, P2PPeerNode;

@protocol P2PFileChunkRequestDelegate <NSObject>

/** Delegate method called by a request object indicating that it did receive a response

 @param request The request object that received a response
 @param chunk The response that was received
 */
- (void)fileChunkRequest:(P2PFileChunkRequest *)request didRecieveChunk:(P2PFileChunk *)chunk;

/** Delegate method called by a request object that has failed.

 @param request The request object that failed
 @param error The error that occurred
 */
- (void)fileChunkRequest:(P2PFileChunkRequest *)request failedWithError:(P2PTransmissionError)error;

@end



@interface P2PFileChunkRequest : P2PTransmittableObject

/** The delegate to recieve updates for this request */
@property (weak, nonatomic) id<P2PFileChunkRequestDelegate> delegate;

/** The file identifier of the chunk we need */
@property (copy, nonatomic, readonly) NSString *fileId;

/** The specific chunk identifier that is being requested */
@property (nonatomic, readonly) NSUInteger chunkId;

/** The size of the chunk we are expecting */
@property (nonatomic, readonly) NSUInteger chunkSize;


/** Creates a new chunk request object with the parameters needed
 
 @param fileId The file identifier of the chunk we need
 @param chunkId The specific chunk identifier that is being requested
 @param chunkSize The size of the chunk we are expecting
 @return A new chunk request object
 */
- (id)initWithFileId:(NSString *)fileId chunkId:(NSUInteger)chunkId chunkSize:(NSUInteger)chunkSize;

@end
