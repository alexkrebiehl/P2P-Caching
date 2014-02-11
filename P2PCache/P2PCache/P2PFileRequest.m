//
//  P2PFileRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileRequest.h"
#import "P2PPeerManager.h"
#import "P2PPeer.h"

@implementation P2PFileRequest
{
    NSMutableArray *_recievedChunks;    // Array of P2PFileChunk objects
}

- (id)initWithFileName:(NSString *)fileName
{
    if ( self = [super init] )
    {
        _fileName = fileName;
        _status = P2PFileRequestStatusNotStarted;
    }
    return self;
}

- (void)getFile
{
    NSArray *peers = [[P2PPeerManager sharedManager] peerList];
    for ( P2PPeer *aPeer in peers )
    {
        [aPeer getFileAvailabilityForRequest:self];
    }
}

- (void)peer:(P2PPeer *)peer didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    
}

@end
