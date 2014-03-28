//
//  P2PPeer.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//



#import "P2PPeerNode.h"
#import "SimplePing.h"
#import "P2PFileRequest.h"
#import "P2PFileChunkRequest.h"
#import "P2PFileChunk.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

@interface P2PPeerNode() <NSNetServiceDelegate, NSStreamDelegate>

@end


@implementation P2PPeerNode
{
//    NSMutableArray *_pendingFileAvailibilityRequests;
//    NSMutableArray *_pendingFileChunkRequests;
    NSMutableDictionary *_pendingRequests;
}

static dispatch_queue_t dispatchQueuePeerNode = nil;
- (id)init
{
    return [self initWithNetService:nil];
}

- (id)initWithNetService:(NSNetService *)netService
{
    if ( self = [super init] )
    {
        NSAssert( netService != nil, @"Cannot init with a nil netService!" );
        
        _isReady = NO;
        
        _netService = netService;
        _netService.delegate = self;
        
        if ( dispatchQueuePeerNode == nil )
        {
            dispatchQueuePeerNode = dispatch_queue_create("dispatchQueuePeerNode", DISPATCH_QUEUE_SERIAL);
        }
    }
    return self;
}

- (void)preparePeer
{
    // Resolve addresses
//    [_netService resolveWithTimeout:0];
    
    // open streams
    NSInputStream		*inStream;
    NSOutputStream		*outStream;
    if ( [_netService getInputStream:&inStream outputStream:&outStream] )
    {
        P2PLog( P2PLogLevelNormal, @"%@ - Successfully connected to peer's stream", self);
        [self takeOverInputStream:inStream outputStream:outStream]; // forService:_netService];
        [self peerDidBecomeReady];
    }
    else
    {
        P2PLog( P2PLogLevelError, @"***** Failed connecting to server *******" );
        [self peerIsNoLongerReady];
    }
    
}


- (void)handleRecievedObject:(P2PTransmittableObject *)object from:(P2PNodeConnection *)sender
{
    P2PTransmittableObject *requestingObject = [_pendingRequests objectForKey:object.responseForRequestId];
    assert( requestingObject != nil );
    
    [_pendingRequests removeObjectForKey:requestingObject.requestId];
    object.associatedNode = self;
    [requestingObject peer:self didRecieveResponse:object];
}

- (void)peerDidBecomeReady
{
    _isReady = YES;
    [self.delegate peerDidBecomeReady:self];
}

- (void)peerIsNoLongerReady
{
    _isReady = NO;
    
    // Make any object transfers fail
#warning Finish implementing failure notifications
    dispatch_async(dispatchQueuePeerNode, ^
    {
        for ( P2PTransmittableObject *obj in [_pendingRequests allValues] )
        {
            [obj peer:self failedToRecieveResponseWithError:P2PTransmissionErrorPeerNoLongerReady];
        }
        _pendingRequests = nil;
    });
    
    [self.delegate peerIsNoLongerReady:self];
}


- (void)netServiceDidStop:(NSNetService *)sender
{
    [self peerIsNoLongerReady];
}

- (void)connection:(P2PNodeConnection *)node failedWithStreamError:(NSStreamEvent)errorEvent
{
    [super connection:node failedWithStreamError:errorEvent];
    [self peerIsNoLongerReady];
}

- (void)sendObjectToPeer:(P2PTransmittableObject *)object
{
    dispatch_async(dispatchQueuePeerNode, ^
    {
        if ( object.shouldWaitForResponse )
        {
            if ( _pendingRequests == nil )
            {
                _pendingRequests = [[NSMutableDictionary alloc] init];
            }
            [_pendingRequests setObject:object forKey:object.requestId];
        }

        [self transmitObject:object];
        P2PLogDebug(@"%@ - File availability request sent", self);
    });
}

//#pragma mark - File Handling
//- (void)requestFileAvailability:(P2PPeerFileAvailibilityRequest *)request
//{
//    dispatch_async(dispatchQueuePeerNode, ^
//    {
////        if ( _pendingFileAvailibilityRequests == nil )
////        {
////            _pendingFileAvailibilityRequests = [[NSMutableArray alloc] init];
////        }
////                [_pendingFileAvailibilityRequests addObject:request];
//        
//        
//        if ( _pendingRequests == nil )
//        {
//            _pendingRequests = [[NSMutableDictionary alloc] init];
//        }
//        [_pendingRequests setObject:request forKey:request.requestId];
//
//        [self transmitObject:request];
//        P2PLogDebug(@"%@ - File availability request sent", self);
//    });
//}

//- (void)didRecieveFileAvailabilityResponse:(P2PPeerFileAvailbilityResponse *)response
//{
//    dispatch_async(dispatchQueuePeerNode, ^
//    {
//        
//        // Find out what request this response is for...
//        for ( P2PPeerFileAvailibilityRequest *aRequest in _pendingFileAvailibilityRequests )
//        {
//            //good enough for now..
//            if ( aRequest.requestId == response.requestId )
//            {
//                // found the request.....
//                response.owningPeer = self;
//                [aRequest didRecieveAvailibilityResponse:response];
//                [_pendingFileAvailibilityRequests removeObject:aRequest];
//                return;
//            }
//        }
//    });
//}

//- (void)requestFileChunk:(P2PFileChunkRequest *)request
//{
//    dispatch_async(dispatchQueuePeerNode, ^
//    {
////        if ( _pendingFileChunkRequests == nil )
////        {
////            _pendingFileChunkRequests = [[NSMutableArray alloc] init];
////        }
////        
////        [_pendingFileChunkRequests addObject:request];
//        
//        if ( _pendingRequests == nil )
//        {
//            _pendingRequests = [[NSMutableSet alloc] init];
//        }
//        
//        [_pendingRequests addObject:request];
//        [self transmitObject:request];
//    });
//}

//- (void)didRecieveFileChunk:(P2PFileChunk *)fileChunk
//{
//    dispatch_async(dispatchQueuePeerNode, ^
//    {
//        
//        
//        for ( P2PFileChunkRequest *aRequest in _pendingFileChunkRequests )
//        {
//            //good enough for now..
//            if ( [aRequest.fileId isEqualToString:fileChunk.fileId] && aRequest.chunkId == fileChunk.chunkId )
//            {
//                // found the request.....
//                [aRequest peer:self didRecieveChunk:fileChunk];
//                [_pendingFileAvailibilityRequests removeObject:aRequest];
//                return;
//            }
//        }
//    });
//}






#pragma mark - Logging
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), self.netService.name];
}
@end
