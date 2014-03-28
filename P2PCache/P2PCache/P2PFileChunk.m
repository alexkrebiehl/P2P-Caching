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
static NSString *P2PFileChunkDecodeKeyFileName =    @"FileName";
static NSString *P2PFileChunkDecodeKeyFileSize =    @"TotalSize";

@implementation P2PFileChunk



- (id)initWithData:(NSData *)data chunkId:(NSUInteger)chunkId fileId:(NSString *)fileId fileName:(NSString *)filename totalFileSize:(NSUInteger)totalSize
{
    assert( data != nil );
    assert( fileId != nil );
    
    if ( self = [super init] )
    {
        _dataBlock = data;
        _chunkId = chunkId;
        _fileId = fileId;
        _fileName = filename;
        _totalFileSize = totalSize;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super initWithCoder:aDecoder] )
    {
        _dataBlock = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyDataBlock];
        _chunkId = [[aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyChunkId] unsignedIntegerValue];
        _fileId = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyFileId];
        _fileName = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyFileName];
        _totalFileSize = [[aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyFileSize] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.dataBlock forKey:P2PFileChunkDecodeKeyDataBlock];
    [aCoder encodeObject:@( self.chunkId ) forKey:P2PFileChunkDecodeKeyChunkId];
    [aCoder encodeObject:self.fileId forKey:P2PFileChunkDecodeKeyFileId];
    [aCoder encodeObject:self.fileName forKey:P2PFileChunkDecodeKeyFileName];
    [aCoder encodeObject:@( self.totalFileSize ) forKey:P2PFileChunkDecodeKeyFileSize];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ - id:%@ [%lu]>", [self class], self.fileId, (unsigned long)self.chunkId];
}

@end
