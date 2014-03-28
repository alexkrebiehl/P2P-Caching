//
//  P2PFileChunkRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/13/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileChunkRequest.h"
#import "P2PFileChunk.h"

static NSString *P2PFileChunkRequestFileIdKey =     @"FileId";
static NSString *P2PFileChunkRequestChunkIdKey =    @"ChunkId";
static NSString *P2PFileChunkRequestChunkSizeKey =  @"ChunkSize";

@implementation P2PFileChunkRequest

- (id)init
{
    return [self initWithFileId:nil chunkId:0 chunkSize:0];
}

- (id)initWithFileId:(NSString *)fileId chunkId:(NSUInteger)chunkId chunkSize:(NSUInteger)chunkSize
{
    assert( fileId != nil );
    assert( chunkSize != 0 );
    
    if ( self = [super init] )
    {
        _fileId = fileId;
        _chunkId = chunkId;
        _chunkSize = chunkSize;
        
        // This request needs to have a response
        self.shouldWaitForResponse = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *fileId = [aDecoder decodeObjectForKey:P2PFileChunkRequestFileIdKey];
    NSUInteger chunkId = [[aDecoder decodeObjectForKey:P2PFileChunkRequestChunkIdKey] unsignedIntegerValue];
    NSUInteger chunkSize = [[aDecoder decodeObjectForKey:P2PFileChunkRequestChunkSizeKey] unsignedIntegerValue];
    
    if ( self = [super initWithCoder:aDecoder] )
    {
        _fileId = fileId;
        _chunkId = chunkId;
        _chunkSize = chunkSize;
        
    }
    
    return [self initWithFileId:fileId chunkId:chunkId chunkSize:chunkSize];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.fileId forKey:P2PFileChunkRequestFileIdKey];
    [aCoder encodeObject:@( self.chunkId ) forKey:P2PFileChunkRequestChunkIdKey];
    [aCoder encodeObject:@( self.chunkSize ) forKey:P2PFileChunkRequestChunkSizeKey];
}

- (void)peer:(P2PNode *)peer didRecieveResponse:(P2PTransmittableObject *)recievedObject
{
    assert( [recievedObject isMemberOfClass:[P2PFileChunk class]] );
    [super peer:peer didRecieveResponse:recievedObject];
    
    [self.delegate fileChunkRequest:self didRecieveChunk:(P2PFileChunk *)recievedObject];
    
}

//- (void)peer:(P2PPeerNode *)node didRecieveChunk:(P2PFileChunk *)chunk
//{
//    [self.delegate fileChunkRequest:self didRecieveChunk:chunk];
//}

//- (void)peer:(P2PPeerNode *)node failedToRecieveChunkWithError:(NSStreamEvent)event
//{
//    [self.delegate fileChunkRequestDidFail:self];
//}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ - id:%@ [%lu]>", [self class], self.fileId, (unsigned long)self.chunkId];
}




@end
