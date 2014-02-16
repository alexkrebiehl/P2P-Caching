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

- (void)fileChunkRequest:(P2PFileChunkRequest *)request didRecieveChunk:(P2PFileChunk *)chunk;
- (void)fileChunkRequestDidFail:(P2PFileChunkRequest *)request;

@end



@interface P2PFileChunkRequest : NSObject <NSCoding>

@property (weak, nonatomic) id<P2PFileChunkRequestDelegate> delegate;

@property (copy, nonatomic, readonly) NSString *fileId;
@property (nonatomic, readonly) NSUInteger chunkId;
@property (nonatomic, readonly) NSUInteger chunkSize;

- (id)initWithFileId:(NSString *)fileId chunkId:(NSUInteger)chunkId chunkSize:(NSUInteger)chunkSize;

- (void)peer:(P2PPeerNode *)node didRecieveChunk:(P2PFileChunk *)chunk;
- (void)peer:(P2PPeerNode *)node failedToRecieveChunkWithError:(NSStreamEvent)event;

@end
