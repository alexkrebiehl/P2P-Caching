//
//  P2PPeerFileAvailbilityResponse.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

// NSCoding Keys
static NSString *P2PAvailabilityResponseFilenameKey =   @"FileName";
static NSString *P2PAvailabilityResponseChunksKey =     @"Chunks";
static NSString *P2PAvailabilityResponseChunkSizeKey =  @"ChunkSize";
static NSString *P2PAvailabilityResponseId =            @"ID";
static NSString *P2PAvailabilityResponseFileId =        @"FileId";
static NSString *P2PAvailabilityResponseTotalFileSize = @"TotalSize";


@implementation P2PPeerFileAvailbilityResponse

- (id)init
{
    return [self initWithRequest:nil];
}

- (id)initWithRequest:(P2PPeerFileAvailibilityRequest *)request
{
    assert( request != nil );
    if ( self = [super init] )
    {
        _fileName = request.fileName;
        _fileId = request.fileId;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super init] )
    {
        _fileName = [aDecoder decodeObjectForKey:P2PAvailabilityResponseFilenameKey];
        _availableChunks = [aDecoder decodeObjectForKey:P2PAvailabilityResponseChunksKey];
        _chunkSizeInBytes = [[aDecoder decodeObjectForKey:P2PAvailabilityResponseChunkSizeKey] unsignedIntegerValue];
        _requestId = [[aDecoder decodeObjectForKey:P2PAvailabilityResponseId] unsignedIntegerValue];
        _fileId = [aDecoder decodeObjectForKey:P2PAvailabilityResponseFileId];
        _totalFileLength = [[aDecoder decodeObjectForKey:P2PAvailabilityResponseTotalFileSize] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityResponseFilenameKey];
    [aCoder encodeObject:self.availableChunks forKey:P2PAvailabilityResponseChunksKey];
    [aCoder encodeObject:@( self.chunkSizeInBytes ) forKey:P2PAvailabilityResponseChunkSizeKey];
    [aCoder encodeObject:@( self.requestId ) forKey:P2PAvailabilityResponseId];
    [aCoder encodeObject:self.fileId forKey:P2PAvailabilityResponseFileId];
    [aCoder encodeObject:@( self.totalFileLength ) forKey:P2PAvailabilityResponseTotalFileSize];
}

@end
