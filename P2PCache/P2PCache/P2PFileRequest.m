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
#import "P2PFileInfo.h"

#define P2PMaximumSimultaneousFileRequests 10

@interface P2PFileRequest() <P2PFileChunkRequestDelegate, P2PPeerFileAvailabilityDelegate>
@end

@implementation P2PFileRequest
{
    NSMutableSet *_pendingAvailabilityRequests;     // Availability requests waiting for a response
    NSMutableDictionary *_receivedAvailabiltyResponses;    // Availability responses received
    
    NSArray *_matchingFileIds;                      // Used when multiple Ids match a given file name
    
    NSMutableSet *_chunksCurrentlyBeingRequested;

    dispatch_queue_t _dispatchQueueFileRequest;      // Each request will run on its on thread
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

- (id)initWithFileId:(NSString *)fileId filename:(NSString *)filename
{
    NSAssert( fileId != nil || filename != nil, @"Must supply a fileId or filename");
    return [self initWithFileInfo:[[P2PFileManager sharedManager] fileInfoForFileId:fileId filename:filename]];
}


static NSUInteger nextFileRequestId = 0;
NSUInteger getNextFileRequestId() { return nextFileRequestId++; }

/** Designated initializer */
- (id)initWithFileInfo:(P2PFileInfo *)info
{
    assert( info != nil );
    if ( self = [super init] )
    {
        _status = P2PFileRequestStatusNotStarted;
		_receivedAvailabiltyResponses = [[NSMutableDictionary alloc] init];
        _chunksCurrentlyBeingRequested = [[NSMutableSet alloc] init];
        _fileInfo = info;
        
        NSString *queueName = [NSString stringWithFormat:@"dispatchQueueFileRequest%lu", (unsigned long)getNextFileRequestId()];
        _dispatchQueueFileRequest = dispatch_queue_create( queueName.UTF8String, DISPATCH_QUEUE_SERIAL );
    }
    return self;
}

#pragma mark - File handling
- (void)getFile
{
    [P2PFileRequest addRequestToPendingList:self];
    assert( _fileInfo != nil );
    
    // Launch the file retrieval process off the main thread...
    // We'll see how this goes...
    dispatch_async(_dispatchQueueFileRequest, ^
    {
        NSAssert( _status == P2PFileRequestStatusNotStarted, @"The request can only be started once");
        
        _status = P2PFileRequestStatusCheckingAvailability;

        [_fileInfo chunksBecameAvailable:[_fileInfo chunksOnDisk]];

        if ( [self fileIsComplete] )
        {
            // No need to do anything more
            [self requestDidComplete];
        }
        else
        {
            NSArray *peers = [[P2PPeerManager sharedManager] activePeers];
            _pendingAvailabilityRequests = [[NSMutableSet alloc] initWithCapacity:[peers count]];
            for ( P2PPeerNode *aPeer in peers )
            {
                P2PPeerFileAvailibilityRequest *availabilityRequest = [[P2PPeerFileAvailibilityRequest alloc] initWithFileId:self.fileInfo.fileId filename:self.fileInfo.filename];
                [_pendingAvailabilityRequests addObject:availabilityRequest];
                availabilityRequest.delegate = self;
                [aPeer sendObjectToPeer:availabilityRequest];
            }
        }
    });
}

- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request failedWithError:(P2PTransmissionError)error;
{
    dispatch_async(_dispatchQueueFileRequest, ^
    {
        P2PLog( P2PLogLevelWarning, @"%@ - failed", request );
        
        if ( error == P2PTransmissionErrorPeerNoLongerReady )
        {
            [self peerBecameUnavailable:request.associatedNode];
        }
        
        [_pendingAvailabilityRequests removeObject:request];
        [self processResponses];
    });
}

- (void)fileAvailabilityRequest:(P2PPeerFileAvailibilityRequest *)request didRecieveAvailibilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    dispatch_async(_dispatchQueueFileRequest, ^
    {
        assert( self.fileInfo != nil );
        // Somehow assemble responses from all peers here
        P2PLogDebug( @"%@ - recieved response from %@", self, response.associatedNode );
        [_pendingAvailabilityRequests removeObject:request];
        
        // If they have no files available for us, we dont need to do anything
        if ( [[response matchingFileIds] count] > 0 )
        {
            [_receivedAvailabiltyResponses setObject:response forKey:response.associatedNode.nodeID];
            
            
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
            else if ( self.fileInfo.fileId == nil )
            {
                // Well since we dont have a file Id yet, we'll just go with what the first responder has
                self.fileInfo.fileId = peersFileId;
                
            }
            else if ( ![self.fileInfo.fileId isEqualToString:peersFileId] )
            {
                // This peer responded with a file Id that did not match our file Id.
                // We're done
                _matchingFileIds = @[ self.fileInfo.fileId, peersFileId ];
                [self failWithError:P2PFileRequestErrorMultipleIdsForFile];
                return;
            }
            
            if ( self.fileInfo.totalFileSize == 0 )
            {
                self.fileInfo.totalFileSize = [response chunkSizeInBytes] * [response totalChunks];
            }
            assert( self.fileInfo != nil );
            assert( [response chunkSizeInBytes] * [response totalChunks] == self.fileInfo.totalFileSize );
            
            // Record the chunks this peer has available
            [self.fileInfo chunksBecameAvailable:[response availableChunks]];
            
    #warning We need to determine how to set chunk unavailable if the peer disconnects (and no other peer has the chunks they had)
       
        }
        _status = P2PFileRequestStatusRetreivingFile;
        [self processResponses];
    });
}

- (void)processResponses
{
    // We dont need to use a dispatch queue here... this method can only be called internally by a method already on that thread
    
    // See if we ever even recieved all of our availabililty responses
    if ( _status == P2PFileRequestStatusCheckingAvailability && [_pendingAvailabilityRequests count] == 0 )
    {
        [self failWithError:P2PFileRequestErrorFileNotFound];
    }

    // Make sure we only process responses if the request is still active
    if ( _status == P2PFileRequestStatusRetreivingFile )
    {
        if ( [_pendingAvailabilityRequests count] == 0 && ([self.fileInfo.chunksAvailable count] < self.fileInfo.totalChunks || self.fileInfo.totalChunks == 0) && [_chunksCurrentlyBeingRequested count] == 0 )
        {
            if ( self.fileInfo.totalChunks == 0 )
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
            NSMutableSet *chunksNeeded = [[NSMutableSet alloc] initWithSet:self.fileInfo.chunksAvailable copyItems:YES];
            [chunksNeeded minusSet:self.fileInfo.chunksOnDisk];  // We don't need chunks that we already have
            [chunksNeeded minusSet:_chunksCurrentlyBeingRequested]; // These already have a filechunkrequest going
            

#warning We need to work on this to much enumeration. 
            
            for ( P2PPeerFileAvailbilityResponse *response in _receivedAvailabiltyResponses.allValues )
            {
                // See if this peer has a chunk we still need
                NSSet *chunksToGetFromPeer = [chunksNeeded objectsPassingTest:^BOOL(NSNumber *chunkId, BOOL *stop)
                {
                    return [[response availableChunks] containsObject:chunkId];
                }];
                for ( NSNumber *aChunk in chunksToGetFromPeer )
                {
                    P2PFileChunkRequest *chunkRequest = [[P2PFileChunkRequest alloc] initWithFileId:self.fileInfo.fileId chunkId:[aChunk unsignedIntegerValue] chunkSize:response.chunkSizeInBytes];
                    if ( [self requestFileChunk:chunkRequest fromPeer:response.associatedNode] )
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
}

/** Sends a file chunk request to a peer.
 @return YES if the chunk can be sent right now, NO if we've reached the maximum number of simultaneous requests
 */
- (bool)requestFileChunk:(P2PFileChunkRequest *)request fromPeer:(P2PPeerNode *)node
{
    // We don't need to use a dispatch queue here... this method can only be called internally by a method already on that thread
    
    assert( request != nil );
    assert( node != nil );
    if ( [_chunksCurrentlyBeingRequested count] < P2PMaximumSimultaneousFileRequests )
    {
        request.delegate = self;
        [_chunksCurrentlyBeingRequested addObject:@( request.chunkId )];
        [node sendObjectToPeer:request];
        return YES;
    }
    return NO;
}




#pragma mark - File Chunk Request Delegate Methods
- (void)fileChunkRequest:(P2PFileChunkRequest *)request didRecieveChunk:(P2PFileChunk *)chunk
{
    dispatch_async(_dispatchQueueFileRequest, ^
    {
        [_chunksCurrentlyBeingRequested removeObject:@( request.chunkId )];
        [_pendingFileRequests removeObject:request];
        [[P2PFileManager sharedManager] fileRequest:self didRecieveFileChunk:chunk];
        
        // Update our available chunks set
        assert( self.fileInfo.fileId != nil );
        
        if ( [self fileIsComplete] )
        {
            [self requestDidComplete];
        }
        else
        {
            [self processResponses];
        }
    });
}

- (void)fileChunkRequest:(P2PFileChunkRequest *)request failedWithError:(P2PTransmissionError)error
{
    dispatch_async( _dispatchQueueFileRequest, ^
    {
        // Mark this chunk as no longer available from this peer somehow...
//        NSAssert(NO, @"To be handled...");
        
        if ( error == P2PTransmissionErrorPeerNoLongerReady )
        {
            [self peerBecameUnavailable:request.associatedNode];
        }

        [_chunksCurrentlyBeingRequested removeObject:@( request.chunkId )];
        [self processResponses];
    });
}

- (void)peerBecameUnavailable:(P2PNode *)node
{
    P2PPeerFileAvailbilityResponse *response = [_receivedAvailabiltyResponses objectForKey:node.nodeID];
    
    [self.fileInfo chunkBecameUnavailable:response.availableChunks];
    [_receivedAvailabiltyResponses removeObjectForKey:node.nodeID];
}



#pragma mark - Methods terminating the transfer
- (bool)fileIsComplete
{
#warning make these properties thread safe
    if ( self.fileInfo.totalChunks == 0 )
    {
        return NO;
    }
    return self.fileInfo.totalChunks == [self.fileInfo.chunksOnDisk count];
}

- (void)failWithError:(P2PFileRequestError)errorCode
{
    // We don't need to use a dispatch queue here... this method can only be called internally by a method already on that thread
    
    _status = P2PFileRequestStatusFailed;
    _errorCode = errorCode;
    
    // Call additional delegate methods depending on the type of error
    switch ( errorCode )
    {
        case P2PFileRequestErrorMultipleIdsForFile:
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [self.delegate fileRequest:self didFindMultipleIds:_matchingFileIds forFileName:self.fileInfo.filename];
            });
            
            break;
        }
        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileRequestDidFail:self withError:errorCode];
        [P2PFileRequest removeRequestFromPendingList:self];
    });
}

- (void)requestDidComplete
{
    _status = P2PFileRequestStatusComplete;
    _dispatchQueueFileRequest = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.delegate fileRequestDidComplete:self];
        [P2PFileRequest removeRequestFromPendingList:self];
    });
}

- (void)abortRequest
{
    dispatch_async(_dispatchQueueFileRequest, ^
    {
        [self failWithError:P2PFileRequestErrorCanceled];
    });
}

@end
