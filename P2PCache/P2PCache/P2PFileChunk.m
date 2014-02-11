//
//  P2PFileChunk.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileChunk.h"

static NSString *P2PFileChunkDecodeKeyDataBlock =       @"DataBlock";
static NSString *P2PFileChunkDecodeKeyStartPosition =   @"StartPosition";

@implementation P2PFileChunk

+ (NSArray *)splitData:(NSData *)data intoChunksOfSize:(NSUInteger)chunkSize
{
    NSUInteger length = [data length];
    NSUInteger offset = 0;
    
    NSMutableArray *chunksOdata = [[NSMutableArray alloc] initWithCapacity:ceil( length / chunkSize )];
    
    do
    {
        NSUInteger thisChunkSize = length - offset > chunkSize ? chunkSize : length - offset;
//        NSData *chunk = [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
//                                             length:thisChunkSize
//                                       freeWhenDone:NO];
        NSData *chunk = [data subdataWithRange:NSMakeRange(offset, thisChunkSize)];
        
        P2PFileChunk *p2pChunk = [[P2PFileChunk alloc] initWithData:chunk startPosition:offset];
        [chunksOdata addObject:p2pChunk];
        
        offset += thisChunkSize;
    } while (offset < length);
    
    return chunksOdata;
}

- (id)initWithData:(NSData *)data startPosition:(NSUInteger)startPosition
{
    if ( self = [super init] )
    {
        _dataBlock = data;
        _startPosition = startPosition;
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super init] )
    {
        _dataBlock = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyDataBlock];
        _startPosition = [aDecoder decodeIntegerForKey:P2PFileChunkDecodeKeyStartPosition];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dataBlock forKey:P2PFileChunkDecodeKeyDataBlock];
    [aCoder encodeInteger:self.startPosition forKey:P2PFileChunkDecodeKeyStartPosition];
}

@end
