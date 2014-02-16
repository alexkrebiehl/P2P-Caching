//
//  P2PPeerFileAvailibilityRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerFileAvailibilityRequest.h"
#import "P2PFileRequest.h"

static NSString *P2PAvailabilityRequestFilenameKey =    @"Filename";
static NSString *P2PAvailabilityRequestFileIdKey =      @"FiledId";
static NSString *P2PAvailabilityRequestIdKey =          @"RequestId";

@implementation P2PPeerFileAvailibilityRequest


- (id)init
{
    return [self initWithFileId:nil];
}

static NSUInteger currentId = 1;
- (id)initWithFileId:(NSString *)fileId
{
    NSAssert( fileId != nil, @"Must supply file Id" );
    
    if ( self = [super init] )
    {
        _requestId = currentId++;
        _fileId = fileId;
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityRequestFilenameKey];
    [aCoder encodeObject:@( self.requestId ) forKey:P2PAvailabilityRequestIdKey];
    [aCoder encodeObject:self.fileId forKey:P2PAvailabilityRequestFileIdKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *fileId = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFileIdKey];
    if ( self = [self initWithFileId:fileId] )
    {
        _requestId = [[aDecoder decodeObjectForKey:P2PAvailabilityRequestIdKey] unsignedIntegerValue];
        _fileName = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFilenameKey];
    }
    return self;
}

@end
