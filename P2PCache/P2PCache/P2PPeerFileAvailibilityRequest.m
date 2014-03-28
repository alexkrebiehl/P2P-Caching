//
//  P2PPeerFileAvailibilityRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerFileAvailibilityRequest.h"
#import "P2PFileRequest.h"
#import "P2PPeerFileAvailbilityResponse.h"

static NSString *P2PAvailabilityRequestFilenameKey =    @"Filename";
static NSString *P2PAvailabilityRequestFileIdKey =      @"FiledId";


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

//static NSUInteger currentId = 1;
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename
{
//    NSAssert( fileId != nil || filename != nil, @"Must supply a file Id or filename" );
    
    if ( self = [super init] )
    {
//        _requestId = currentId++;
        _fileId = fileId;
        _fileName = filename;
        self.shouldWaitForResponse = YES;
         
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.fileName forKey:P2PAvailabilityRequestFilenameKey];
//    [aCoder encodeObject:self.requestId forKey:P2PAvailabilityRequestIdKey];
    [aCoder encodeObject:self.fileId forKey:P2PAvailabilityRequestFileIdKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *fileId = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFileIdKey];
    NSString *fileName = [aDecoder decodeObjectForKey:P2PAvailabilityRequestFilenameKey];
    
    if ( self = [super initWithCoder:aDecoder] )
    {
        _fileId = fileId;
        _fileName = fileName;
    }
    
//    if ( self = [self initWithFileId:fileId filename:fileName] )
//    {
////        self.requestId = [aDecoder decodeObjectForKey:P2PAvailabilityRequestIdKey];
//    }
    return self;
}

- (void)didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    [self.delegate fileAvailabilityRequest:self didRecieveAvailibilityResponse:response];
}

- (void)failedWithStreamEvent:(NSStreamEvent)event
{
    [self.delegate fileAvailabilityRequest:self failedWithEvent:event];
}

- (void)peer:(P2PNode *)peer didRecieveResponse:(P2PTransmittableObject *)recievedObject
{
    assert( [recievedObject isMemberOfClass:[P2PPeerFileAvailbilityResponse class]] );
    [self.delegate fileAvailabilityRequest:self didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)recievedObject];
}

@end
