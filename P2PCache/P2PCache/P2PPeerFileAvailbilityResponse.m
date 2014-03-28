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
static NSString *P2PAvailabilityResponseFilenameKey =       @"FileName";
static NSString *P2PAvailabilityResponseChunksKey =         @"Chunks";
static NSString *P2PAvailabilityResponseChunkSizeKey =      @"ChunkSize";
static NSString *P2PAvailabilityResponseId =                @"ID";
static NSString *P2PAvailabilityResponseMatchingFileIds =   @"MatchingIds";
static NSString *P2PAvailabilityResponseTotalChunks =       @"TotalChunks";


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
        self.responseForRequestId = request.requestId;
        
        if ( request.fileId != nil )
        {
            _matchingFileIds = @[ request.fileId ];
        }
        else
        {
            _matchingFileIds = [[NSArray alloc] init];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ( self = [super initWithCoder:aDecoder] )
    {
        _fileName = [aDecoder decodeObjectForKey:P2PAvailabilityResponseFilenameKey];
        _availableChunks = [NSMutableSet setWithArray:[aDecoder decodeObjectForKey:P2PAvailabilityResponseChunksKey]];
        _chunkSizeInBytes = [[aDecoder decodeObjectForKey:P2PAvailabilityResponseChunkSizeKey] unsignedIntegerValue];
        _matchingFileIds = [aDecoder decodeObjectForKey:P2PAvailabilityResponseMatchingFileIds];
        _totalChunks = [[aDecoder decodeObjectForKey:P2PAvailabilityResponseTotalChunks] unsignedIntegerValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityResponseFilenameKey];
    [aCoder encodeObject:[self.availableChunks allObjects] forKey:P2PAvailabilityResponseChunksKey];
    [aCoder encodeObject:@( self.chunkSizeInBytes ) forKey:P2PAvailabilityResponseChunkSizeKey];
    [aCoder encodeObject:self.matchingFileIds forKey:P2PAvailabilityResponseMatchingFileIds];
    [aCoder encodeObject:@( self.totalChunks ) forKey:P2PAvailabilityResponseTotalChunks];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ - %@ (%lu/%lu)>", NSStringFromClass([self class]), self.fileName, (unsigned long)[self.availableChunks count], (unsigned long)self.totalChunks];
}

@end
