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
    return [self initWithFileId:nil filename:nil];
}

- (id)initWithFileId:(NSString *)fileId
{
    return [self initWithFileId:fileId filename:nil];
}

- (id)initWithFilename:(NSString *)filename
{
    return [self initWithFileId:nil filename:filename];
}

static NSUInteger currentId = 1;
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename
{
    NSAssert( fileId != nil || filename != nil, @"Must supply a file Id or filename" );
    
    if ( self = [super init] )
    {
        _requestId = currentId++;
        _fileId = fileId;
        _fileName = filename;
         
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
    NSString *fileName = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFilenameKey];
    if ( self = [self initWithFileId:fileId filename:fileName] )
    {
        _requestId = [[aDecoder decodeObjectForKey:P2PAvailabilityRequestIdKey] unsignedIntegerValue];
    }
    return self;
}

- (void)didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    [self.delegate fileAvailabilityRequest:self didRecieveAvailibilityResponse:response];
}

@end
