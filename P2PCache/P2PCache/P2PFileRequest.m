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
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

@interface P2PPeerFileAvailbilityResponse (P2PFileRequestExtension)

@end

@interface P2PFileRequest() <P2PFileChunkRequestDelegate, P2PPeerFileAvailabilityDelegate>

@end

@implementation P2PFileRequest
{
    NSMutableArray *_recievedChunks;                // Array of P2PFileChunk objects
    NSMutableArray *_recievedAvailabiltyResponses;  // Availability responses recieved
    
    NSArray *_matchingFileIds;                      // Used when multiple Ids match a given file name
}

static NSMutableArray *_pendingFileRequests = nil;
+ (NSArray *)pendingFileRequests
{
    if ( _pendingFileRequests == nil )
    {
        _pendingFileRequests = [[NSMutableArray alloc] init];
    }
    return _pendingFileRequests;
}

+ (void)addRequestToPendingList:(P2PFileRequest *)request
{
    if ( _pendingFileRequests == nil )
    {
        _pendingFileRequests = [[NSMutableArray alloc] init];
    }
    [_pendingFileRequests addObject:request];
}

+ (void)removeRequestFromPendingList:(P2PFileRequest *)request
{
    [_pendingFileRequests removeObject:request];
}

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

- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename
{
    NSAssert( fileId != nil || filename != nil, @"Must supply a fileId");
    if ( self = [super init] )
    {
        _fileId = fileId;
        _fileName = filename;
        _status = P2PFileRequestStatusNotStarted;
    }
    return self;
}

- (void)getFile
{
    NSAssert( _status == P2PFileRequestStatusNotStarted, @"The request can only be started once");
    
    [P2PFileRequest addRequestToPendingList:self];
    
    _status = P2PFileRequestStatusCheckingAvailability;
    NSArray *peers = [[P2PPeerManager sharedManager] activePeers];
    for ( P2PPeerNode *aPeer in peers )
    {
        P2PPeerFileAvailibilityRequest *availabilityRequest = [[P2PPeerFileAvailibilityRequest alloc] initWithFileId:self.fileId filename:self.fileName];
        availabilityRequest.delegate = self;
        [aPeer requestFileAvailability:availabilityRequest];
    }
}

- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    // Somehow assemble responses from all peers here
    P2PLogDebug(@"%@ - recieved response from %@", self, response.owningPeer);
    
    // If they have no files available for us, we dont need to do anything
    if ( [[response matchingFileIds] count] > 0 )
    {
        if ( _recievedAvailabiltyResponses == nil )
        {
            _recievedAvailabiltyResponses = [[NSMutableArray alloc] init];
        }
        [_recievedAvailabiltyResponses addObject:response];
        
        // First thing we need to make sure of is that we're getting the same file ID from every response
        // and only one matching file ID
        NSString *peersFileId = [[response matchingFileIds] firstObject];
        if ( [[response matchingFileIds] count] > 1 )
        {
            // Too many Ids were returned.  There's nothing more this request can do
            _matchingFileIds = response.matchingFileIds;
            [self failWithError:P2PFileRequestErrorMultipleIdsForFile];
            return;
        }
        else if ( self.fileId == nil )
        {
            // Well since we dont have a file Id yet, we'll just go with what the first responder has
            _fileId = peersFileId;
        }
        else if ( ![self.fileId isEqualToString:peersFileId] )
        {
            // This peer responded with a file Id that did not match our file Id.
            // We're done
            _matchingFileIds = @[ self.fileId, peersFileId ];
            [self failWithError:P2PFileRequestErrorMultipleIdsForFile];
            return;
        }
        
        NSAssert( [[_recievedAvailabiltyResponses firstObject] totalFileLength] == [response totalFileLength], @"Inconsistent file lengths" );
        
        [self processResponses];
     }
}

- (void)processResponses
{
    // For now we'll just download whatever the peer as available
    // eventually we'll be smarter about this...
    for ( P2PPeerFileAvailbilityResponse *response in _recievedAvailabiltyResponses )
    {
        for ( NSNumber *aChunk in response.availableChunks )
        {
            P2PFileChunkRequest *chunkRequest = [[P2PFileChunkRequest alloc] initWithFileId:self.fileId chunkId:[aChunk unsignedIntegerValue] chunkSize:response.chunkSizeInBytes];
            [self requestFileChunk:chunkRequest fromPeer:response.owningPeer];
        }
    }
    
}

- (void)requestFileChunk:(P2PFileChunkRequest *)request fromPeer:(P2PPeerNode *)peer
{
    assert( request != nil );
    assert( peer != nil );
    _status = P2PFileRequestStatusRetreivingFile;
    request.delegate = self;
    [peer requestFileChunk:request];
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
    LogSelector();
}

- (void)failWithError:(P2PFileRequestError)errorCode
{
    _status = P2PFileRequestStatusFailed;
    _errorCode = errorCode;
    
    // Call additional delegate methods depending on the type of error
    switch ( errorCode )
    {
        case P2PFileRequestErrorMultipleIdsForFile:
        {
            [self.delegate fileRequest:self didFindMultipleIds:_matchingFileIds forFileName:self.fileName];
            break;
        }
        default:
            break;
    }
    
    
    [self.delegate fileRequestDidFail:self withError:errorCode];
    [P2PFileRequest removeRequestFromPendingList:self];
}

- (void)requestDidComplete
{
    _status = P2PFileRequestStatusComplete;
    [self.delegate fileRequestDidComplete:self];
    [P2PFileRequest removeRequestFromPendingList:self];
}

@end
