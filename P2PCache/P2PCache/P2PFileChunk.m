//
//  P2PFileChunk.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileChunk.h"

static NSString *P2PFileChunkDecodeKeyDataBlock =   @"DataBlock";
static NSString *P2PFileChunkDecodeKeyChunkId =     @"ChunkID";
static NSString *P2PFileChunkDecodeKeyFileId =      @"FileId";

@implementation P2PFileChunk



- (id)initWithData:(NSData *)data chunkId:(NSUInteger)chunkId fileId:(NSString *)fileId
{
    assert( data != nil );
    assert( fileId != nil );
    
    if ( self = [super init] )
    {
        _dataBlock = data;
        _chunkId = chunkId;
        _fileId = fileId;
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super init] )
    {
        _dataBlock = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyDataBlock];
        _chunkId = [[aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyChunkId] unsignedIntegerValue];
        _fileId = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyFileId];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dataBlock forKey:P2PFileChunkDecodeKeyDataBlock];
    [aCoder encodeObject:@( self.chunkId ) forKey:P2PFileChunkDecodeKeyChunkId];
    [aCoder encodeObject:self.fileId forKey:P2PFileChunkDecodeKeyFileId];
}

@end
