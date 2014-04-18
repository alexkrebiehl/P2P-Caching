//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"
#import "P2PPeerFileAvailibilityRequest.h"
#import "NSMutableArray+QueueExtension.h"

#import "P2PNodeConnection.h"

/** Since the peer and server will share a lot of the same functionality,
 I decided to go ahead and just make them children of this superclass.  */

@implementation P2PNode
{
    NSMutableSet *_activeConnections;     // A set of active P2PNodeConnection objects
    NSMutableSet *_activeDataTransfers;   // A set of P2PIncomingData objects
}

static NSUInteger nextNodeID = 0;
NSUInteger getNextNodeID() { return nextNodeID++; }

- (id) init
{
    if ( self = [super init] )
    {
        _nodeID = @( getNextNodeID() );
    }
    return self;
}

- (void)transmitObject:(P2PTransmittableObject *)transmittableObject
{
    [self transmitObject:transmittableObject toNodeConnection:nil];
}

- (void)transmitObject:(P2PTransmittableObject *)transmittableObject toNodeConnection:(P2PNodeConnection *)connection;
{
    if ( connection == nil && [_activeConnections count] == 1 )
    {
        connection = [_activeConnections anyObject];
    }
    
    // If connection is still nil, we can't send this object
    if ( connection == nil )
    {
        [transmittableObject peer:self failedToSendObjectWithError:P2PTransmissionErrorPeerNoLongerReady];
    }
    else
    {
        // Serialize data... Add header and footer to the transmission
        NSData *preparedData = prepareObjectForTransmission( transmittableObject );

        [connection sendDataToConnection:preparedData];
        [transmittableObject peerDidBeginToSendObject:self];
    }
}

#pragma mark - P2PNodeConnectionDelegate
- (void)nodeConnection:(P2PNodeConnection *)connection didRecieveObject:(P2PTransmittableObject *)object
{
    // Default implementation does nothing.  Selector should be overridden by subclasses
}

- (void)nodeConnection:(P2PNodeConnection *)connection failedToDownloadWithError:(P2PIncomingDataErrorCode)errorCode
{
    switch ( errorCode )
    {
        case P2PIncomingDataErrorCodeNoData:
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: NO DATA", connection );
            break;
        case P2PIncomingDataErrorCodeStreamError:
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: Error with stream", connection );
            break;
        case P2PIncomingDataErrorCodeCurruptFile:
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: Currupt file", connection );
            break;
        case P2PIncomingDataErrorCodeInvalidHeader:
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: Invalid header", connection );
            break;
        default:
            break;
    }
}

- (void)nodeConnectionDidEnd:(P2PNodeConnection *)node
{
    [_activeConnections removeObject:node];
    P2PLog( P2PLogLevelWarning, @"%@ - connection lost: %@", self, node);
}

- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream
{
    assert( inStream != nil );
    assert( outStream != nil );
    
    P2PNodeConnection *connection = [[P2PNodeConnection alloc] initWithInputStream:inStream outputStream:outStream];
    connection.delegate = self;
    
    if ( _activeConnections == nil )
    {
        _activeConnections = [[NSMutableSet alloc] init];
    }
    [_activeConnections addObject:connection];
    
    [connection openConnection];
}


- (void)cleanup
{
    for ( P2PNodeConnection *connection in _activeConnections )
    {
        [connection dropConnection];
    }
    _activeConnections = nil;
}

@end

