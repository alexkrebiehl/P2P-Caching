//
//  P2PFileRequest.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/10/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFileRequest.h"
#import "P2PPeerManager.h"
#import "P2PPeerNode.h"
#import "P2PFileChunkRequest.h"

@interface P2PFileRequest() <P2PFileChunkRequestDelegate>

@end

@implementation P2PFileRequest
{
    NSMutableArray *_recievedChunks;                // Array of P2PFileChunk objects
    NSMutableArray *_recievedAvailabiltyResponses;  // Availability responses recieved
}

- (id)init
{
    return [self initWithFileId:nil];
}

- (id)initWithFileId:(NSString *)fileId
{
    NSAssert( fileId != nil, @"Must supply a fileId");
    
    if ( self = [super init] )
    {
        _fileId = fileId;
        _status = P2PFileRequestStatusNotStarted;
    }
    return self;
}

- (void)getFile
{
    _status = P2PFileRequestStatusCheckingAvailability;
    NSArray *peers = [[P2PPeerManager sharedManager] activePeers];
    for ( P2PPeerNode *aPeer in peers )
    {
        [aPeer getFileAvailabilityForRequest:self];
    }
}

- (void)peer:(P2PPeerNode *)peer didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    // Somehow assemble responses from all peers here
    P2PLogDebug(@"%@ - recieved response from %@", self, peer);
    if ( _recievedAvailabiltyResponses == nil )
    {
        _recievedAvailabiltyResponses = [[NSMutableArray alloc] init];
    }
    [_recievedAvailabiltyResponses addObject:response];
    
    [self processResponses];
}

- (void)processResponses
{
    // For now we'll just download whatever the peer as available
    // eventually we'll be smarter about this...
    
}

- (void)requestFileChunk:(P2PFileChunkRequest *)request fromPeer:(P2PPeerNode *)peer
{
    request.delegate = self;
//    [peer requestFileChunk:request];
}

- (void)fileChunkRequest:(P2PFileChunkRequest *)request didRecieveChunk:(P2PFileChunk *)chunk
{
    if ( _recievedChunks == nil )
    {
        _recievedChunks = [[NSMutableArray alloc] init];
    }
    
    [_recievedChunks addObject:chunk];
    [self checkFileCompleteness];
}

- (void)fileChunkRequestDidFail:(P2PFileChunkRequest *)request
{
    
}

- (void)checkFileCompleteness
{
    
}

@end
