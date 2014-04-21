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

//@interface P2PPeerNode() <NSNetServiceDelegate, NSStreamDelegate>
//
//@end
//
//
//@implementation P2PPeerNode
//{
//    NSMutableDictionary *_pendingRequests;
//}

//static dispatch_queue_t dispatchQueuePeerNode = nil;
//- (id)init
//{
//    return [self initWithNetService:nil];
//}

//- (id)initWithNetService:(NSNetService *)netService
//{
//    if ( self = [super init] )
//    {
//        NSAssert( netService != nil, @"Cannot init with a nil netService!" );
//        
//        _isReady = NO;
//        _netService = netService;
//        
////        if ( dispatchQueuePeerNode == nil )
////        {
////            dispatchQueuePeerNode = dispatch_queue_create("dispatchQueuePeerNode", DISPATCH_QUEUE_SERIAL);
////        }
//    }
//    return self;
//}

//- (void)preparePeer
//{
//    // open streams
//    NSInputStream		*inStream;
//    NSOutputStream		*outStream;
//    if ( [_netService getInputStream:&inStream outputStream:&outStream] )
//    {
//        P2PLog( P2PLogLevelNormal, @"%@ - Successfully connected to peer's stream", self);
//        [self takeOverInputStream:inStream outputStream:outStream];
//        [self peerDidBecomeReady];
//    }
//    else
//    {
//        P2PLog( P2PLogLevelError, @"***** Failed connecting to server *******" );
//        [self peerIsNoLongerReady];
//    }
//    
//}


//- (void)nodeConnection:(P2PNodeConnection *)connection didRecieveObject:(P2PTransmittableObject *)object
//{
//    [super nodeConnection:connection didRecieveObject:object];
//    
//    P2PTransmittableObject *requestingObject = [_pendingRequests objectForKey:object.responseForRequestId];
//    if ( requestingObject == nil )
//    {
//        // We recieved an object without a request?
//        P2PLog( P2PLogLevelWarning, @"Recieved an object without making a request: %@ - response to requestId: %@", object, object.responseForRequestId );
//    }
//    else
//    {
//        [_pendingRequests removeObjectForKey:requestingObject.requestId];
//        object.associatedNode = self;
//        [requestingObject peer:self didRecieveResponse:object];
//    }
//}

//- (void)peerDidBecomeReady
//{
//    _isReady = YES;
//    [self.delegate peerDidBecomeReady:self];
//}

//- (void)peerIsNoLongerReady
//{
//    _isReady = NO;
//    
//    // Make any object transfers fail
//#warning Finish implementing failure notifications
//    dispatch_async(dispatchQueuePeerNode, ^
//    {
//        for ( P2PTransmittableObject *obj in [_pendingRequests allValues] )
//        {
//            [obj peer:self failedToRecieveResponseWithError:P2PTransmissionErrorPeerNoLongerReady];
//        }
//        _pendingRequests = nil;
//    });
//    
//    [self.delegate peerIsNoLongerReady:self];
//}

//- (void)nodeConnectionDidEnd:(P2PNodeConnection *)node
//{
//    [super nodeConnectionDidEnd:node];
//    [self peerIsNoLongerReady];
//}

//- (void)sendObjectToPeer:(P2PTransmittableObject *)transmittableObject
//{
//    dispatch_async(dispatchQueuePeerNode, ^
//    {
//        assert( self.isReady );
//        if ( transmittableObject.shouldWaitForResponse )
//        {
//            if ( _pendingRequests == nil )
//            {
//                _pendingRequests = [[NSMutableDictionary alloc] init];
//            }
//            [_pendingRequests setObject:transmittableObject forKey:transmittableObject.requestId];
//        }
//
//        [self transmitObject:transmittableObject];
//    });
//}





//#pragma mark - Logging
//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), self.netService.name];
//}
//@end
