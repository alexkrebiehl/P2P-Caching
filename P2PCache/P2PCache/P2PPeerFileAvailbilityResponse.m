//
//  P2PPeerFileAvailbilityResponse.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerFileAvailbilityResponse.h"

// NSCoding Keys
static NSString *P2PAvailabilityResponseFilenameKey =   @"FileName";
static NSString *P2PAvailabilityResponseChunksKey =     @"Chunks";
static NSString *P2PAvailabilityResponseChunkSizeKey =  @"ChunkSize";


@implementation P2PPeerFileAvailbilityResponse

- (id)initWithFileName:(NSString *)fileName availableChunks:(NSArray *)chunks chunkSize:(NSUInteger)chunkSizeInBytes
{
    if ( self = [super init] )
    {
        _fileName = fileName;
        _availableChunks = chunks;
        _chunkSizeInBytes = chunkSizeInBytes;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *fileName = [aDecoder decodeObjectForKey:P2PAvailabilityResponseFilenameKey];
    NSArray *chunks = [aDecoder decodeObjectForKey:P2PAvailabilityResponseChunksKey];
    NSUInteger chunkSize = [[aDecoder decodeObjectForKey:P2PAvailabilityResponseChunkSizeKey] unsignedIntegerValue];
    return [self initWithFileName:fileName availableChunks:chunks chunkSize:chunkSize];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityResponseFilenameKey];
    [aCoder encodeObject:self.availableChunks forKey:P2PAvailabilityResponseChunksKey];
    [aCoder encodeObject:@( self.chunkSizeInBytes ) forKey:P2PAvailabilityResponseChunkSizeKey];
}

@end
