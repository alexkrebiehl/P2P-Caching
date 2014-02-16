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
static NSString *P2PFileChunkDecodeKeyFileName =        @"Filename";

@implementation P2PFileChunk



- (id)initWithData:(NSData *)data startPosition:(NSUInteger)startPosition fileName:(NSString *)filename
{
    if ( self = [super init] )
    {
        _dataBlock = data;
        _startPosition = startPosition;
        _fileName = filename;
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super init] )
    {
        _dataBlock = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyDataBlock];
        _startPosition = [aDecoder decodeIntegerForKey:P2PFileChunkDecodeKeyStartPosition];
        _fileName = [aDecoder decodeObjectForKey:P2PFileChunkDecodeKeyFileName];
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.dataBlock forKey:P2PFileChunkDecodeKeyDataBlock];
    [aCoder encodeInteger:self.startPosition forKey:P2PFileChunkDecodeKeyStartPosition];
    [aCoder encodeObject:self.fileName forKey:P2PFileChunkDecodeKeyFileName];
}

@end
