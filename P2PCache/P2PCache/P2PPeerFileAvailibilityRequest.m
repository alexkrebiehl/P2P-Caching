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

- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename
{
//    NSAssert( fileId != nil || filename != nil, @"Must supply a file Id or filename" );
    
    if ( self = [super init] )
    {
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
    return self;
}

- (void)peer:(P2PNode *)peer didRecieveResponse:(P2PTransmittableObject *)recievedObject
{
    assert( [recievedObject isMemberOfClass:[P2PPeerFileAvailbilityResponse class]] );
    
    [super peer:peer didRecieveResponse:recievedObject];
    [self.delegate fileAvailabilityRequest:self didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)recievedObject];
}

- (void)peer:(P2PNode *)peer failedToSendObjectWithError:(P2PTransmissionError)error
{
    [super peer:peer failedToSendObjectWithError:error];
    
    [self.delegate fileAvailabilityRequest:self failedWithError:error];
}

- (void)peer:(P2PNode *)peer failedToRecieveResponseWithError:(P2PTransmissionError)error
{
    [super peer:peer failedToRecieveResponseWithError:error];
    
    [self.delegate fileAvailabilityRequest:self failedWithError:error];
}

@end
