//
//  P2PFileListRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 4/25/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileListRequest.h"
#import "P2PFileListResponse.h"

@implementation P2PFileListRequest

- (id)init
{
    if ( self = [super init] )
    {
        self.shouldWaitForResponse = YES;
    }
    return self;
}

#pragma mark - Overridden methods
- (void)peer:(P2PNode *)peer didRecieveResponse:(P2PTransmittableObject *)recievedObject
{
    assert( [recievedObject isMemberOfClass:[P2PFileListResponse class]] );
    
    [super peer:peer didRecieveResponse:recievedObject];
    [self.delegate fileListRequest:self didRecieveResponse:(P2PFileListResponse *)recievedObject];
}

- (void)peer:(P2PNode *)peer failedToSendObjectWithError:(P2PTransmissionError)error
{
    [super peer:peer failedToSendObjectWithError:error];
    
    [self.delegate fileListRequest:self failedWithError:error];
}

- (void)peer:(P2PNode *)peer failedToRecieveResponseWithError:(P2PTransmissionError)error
{
    [super peer:peer failedToRecieveResponseWithError:error];
    
    [self.delegate fileListRequest:self failedWithError:error];
}

@end
