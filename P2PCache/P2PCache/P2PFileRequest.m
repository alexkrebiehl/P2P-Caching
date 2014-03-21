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
#import "P2PFileManager.h"

#define P2PMaximumSimultaneousFileRequests 10

@interface P2PPeerFileAvailbilityResponse (P2PFileRequestExtension)

@end

@interface P2PFileRequest() <P2PFileChunkRequestDelegate, P2PPeerFileAvailabilityDelegate>

@end

@implementation P2PFileRequest
{
    NSMutableArray *_pendingAvailabilityRequests;   // Availability requests waiting for a response
    NSMutableArray *_recievedAvailabiltyResponses;  // Availability responses recieved
    
    NSArray *_matchingFileIds;                      // Used when multiple Ids match a given file name
    
    NSMutableSet *_chunksCurrentlyBeingRequested;
//    NSMutableSet *_chunksAvailable;
//    NSMutableSet *_chunksReady;                   // What chunk IDs are present on the local machine
}


#pragma mark - Internal class methods
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
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PActiveFileRequestsDidChange object:nil];
}

+ (void)removeRequestFromPendingList:(P2PFileRequest *)request
{
    [_pendingFileRequests removeObject:request];
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PActiveFileRequestsDidChange object:nil];
}


#pragma mark - Initialization
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

/** Designated initializer */
- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename
{
    NSAssert( fileId != nil || filename != nil, @"Must supply a fileId");
    if ( self = [super init] )
    {
        _fileId = fileId;
        _fileName = filename;
        _status = P2PFileRequestStatusNotStarted;
        
        // Data structure initialization
        _recievedAvailabiltyResponses = [[NSMutableArray alloc] init];
        _chunksAvailable = [[NSMutableSet alloc] init];
        _chunksReady = [[NSMutableSet alloc] init];
        _chunksCurrentlyBeingRequested = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark - Property implementations
- (NSUInteger)chunksAvailable
{
    return [_chunksAvailable count];
}

- (NSUInteger)chunksReady
{
    return [_chunksReady count];
}

- (double)progress
{
    if ( self.totalChunks == 0 )
    {
        return 0;
    }
    return ((double)self.chunksReady / self.totalChunks) * 100;
}

#pragma mark - File handling
- (void)getFile
{
    // Launch the file retrevial process off the main thread...
    // We'll see how this goes...
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSAssert( _status == P2PFileRequestStatusNotStarted, @"The request can only be started once");
        
        [P2PFileRequest addRequestToPendingList:self];
        
        _status = P2PFileRequestStatusCheckingAvailability;
        
        
        // First thing we should do is check with the file manager to see which chunks we have on hand
        P2PPeerFileAvailibilityRequest *requestToSelf = [[P2PPeerFileAvailibilityRequest alloc] initWithFileId:self.fileId filename:self.fileName];
        P2PPeerFileAvailbilityResponse *responseFromSelf = [[P2PFileManager sharedManager] fileAvailibilityForRequest:requestToSelf];
        for ( NSNumber *chunkId in [responseFromSelf availableChunks] )
        {
            _totalChunks = [responseFromSelf totalChunks];
            [_chunksAvailable addObject:chunkId];
            [_chunksReady addObject:chunkId];
        }
        
        if ( [self fileIsComplete] )
        {
            // No need to do anything more
            [self requestDidComplete];
        }
        else
        {
            NSArray *peers = [[P2PPeerManager sharedManager] activePeers];
            _pendingAvailabilityRequests = [[NSMutableArray alloc] initWithCapacity:[peers count]];
            for ( P2PPeerNode *aPeer in peers )
            {
                P2PPeerFileAvailibilityRequest *availabilityRequest = [[P2PPeerFileAvailibilityRequest alloc] initWithFileId:self.fileId filename:self.fileName];
                [_pendingAvailabilityRequests addObject:availabilityRequest];
                availabilityRequest.delegate = self;
                [aPeer requestFileAvailability:availabilityRequest];
            }
        }
    });
}

- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    // Somehow assemble responses from all peers here
    P2PLogDebug(@"%@ - recieved response from %@", self, response.owningPeer);
    [_pendingAvailabilityRequests removeObject:request];
    
    // If they have no files available for us, we dont need to do anything
    if ( [[response matchingFileIds] count] > 0 )
    {
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
        
        if ( self.totalChunks == 0 )
        {
            _totalChunks = [response totalChunks];
        }
        
        assert( [response totalChunks] == _totalChunks );
        
        // Record the chunks this peer has available
        [_chunksAvailable addObjectsFromArray:[response availableChunks]];
    }
    
    [self processResponses];
}

- (void)processResponses
{
    if ( [_pendingAvailabilityRequests count] == 0 && (self.chunksAvailable < self.totalChunks || self.totalChunks == 0) && [_chunksCurrentlyBeingRequested count] == 0 )
    {
        if ( self.totalChunks == 0 )
        {
            // We couldn't even find the file on the network..
            // Total fail
            [self failWithError:P2PFileRequestErrorFileNotFound];
        }
        else
        {
            // We at least found some information on the file, but couldn't get all of the chunks we need
            [self failWithError:P2PFileRequestErrorMissingChunks];
        }
    }
    
    else
    {
        // Found out what chunks we still need
        NSMutableSet *chunksNeeded = [[NSMutableSet alloc] initWithSet:_chunksAvailable copyItems:YES];
        [chunksNeeded minusSet:_chunksReady];  // We dont need chunks that we already have
        [chunksNeeded minusSet:_chunksCurrentlyBeingRequested]; // These already have a filechunkrequest going
        
        for ( P2PPeerFileAvailbilityResponse *response in _recievedAvailabiltyResponses )
        {
            // See if this peer has a chunk we still need
            NSSet *chunksToGetFromPeer = [chunksNeeded objectsPassingTest:^BOOL(NSNumber *chunkId, BOOL *stop)
            {
                return [[response availableChunks] containsObject:chunkId];
            }];
            for ( NSNumber *aChunk in chunksToGetFromPeer )
            {
                P2PFileChunkRequest *chunkRequest = [[P2PFileChunkRequest alloc] initWithFileId:self.fileId chunkId:[aChunk unsignedIntegerValue] chunkSize:response.chunkSizeInBytes];
                if ( [self requestFileChunk:chunkRequest fromPeer:response.owningPeer] )
                {
                    [chunksNeeded removeObject:aChunk];
                }
                else
                {
                    return;
                }
            }
        }
    }
}

/** Sends a file chunk request to a peer.
 @return YES if the chunk can be sent right now, NO if we've reached the maximum number of simultaneous requests
 */
- (bool)requestFileChunk:(P2PFileChunkRequest *)request fromPeer:(P2PPeerNode *)peer
{
    assert( request != nil );
    assert( peer != nil );
    if ( [_chunksCurrentlyBeingRequested count] < P2PMaximumSimultaneousFileRequests )
    {
        _status = P2PFileRequestStatusRetreivingFile;
        request.delegate = self;
        [_chunksCurrentlyBeingRequested addObject:@( request.chunkId )];
        [peer requestFileChunk:request];
        return YES;
    }
    return NO;
}

- (void)fileChunkRequest:(P2PFileChunkRequest *)request didRecieveChunk:(P2PFileChunk *)chunk
{
    [_chunksCurrentlyBeingRequested removeObject:@( request.chunkId )];
    [_pendingFileRequests removeObject:request];
    [[P2PFileManager sharedManager] fileRequest:self didRecieveFileChunk:chunk];
    
    // Update our available chunks set
    assert( self.fileId != nil );
    [_chunksReady addObjectsFromArray:[[P2PFileManager sharedManager] availableChunksForFileID:self.fileId]];
    
    // Notify the delegate that the chunk was recieved
    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ( [self.delegate respondsToSelector:@selector(fileRequest:didRecieveChunk:)] )
        {
            [self.delegate fileRequest:self didRecieveChunk:chunk];
        }
    });
    
    
    if ( [self fileIsComplete] )
    {
        [self requestDidComplete];
    }
    else
    {
        [self processResponses];
    }
}

- (void)fileChunkRequestDidFail:(P2PFileChunkRequest *)request
{
    NSAssert(NO, @"To be handled...");

    // Mark this chunk as no longer available from this peer somehow...
    
    
    
    [_chunksCurrentlyBeingRequested removeObject:@( request.chunkId )];
    [self processResponses];
}

- (bool)fileIsComplete
{
    if ( self.totalChunks == 0 )
    {
        return NO;
    }
    return self.totalChunks == [_chunksReady count];
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
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.delegate fileRequest:self didFindMultipleIds:_matchingFileIds forFileName:self.fileName];
            });
            
            break;
        }
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileRequestDidFail:self withError:errorCode];
    });
    
    [P2PFileRequest removeRequestFromPendingList:self];
}

- (void)requestDidComplete
{
    _status = P2PFileRequestStatusComplete;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileRequestDidComplete:self];
    });
    
    [P2PFileRequest removeRequestFromPendingList:self];
}

@end
