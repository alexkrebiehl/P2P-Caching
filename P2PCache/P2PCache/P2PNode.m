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
#import <zlib.h>

/** Since the peer and server will share a lot of the same functionality,
 I decided to go ahead and just make them children of this superclass.  */

@interface P2PNode ()

@property (nonatomic, readwrite, strong) NSMutableSet *activeConnections;

@end

@implementation P2PNode


#pragma mark - Initialization
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


#pragma mark - Preparing Connection
- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream
{
    assert( inStream != nil );
    assert( outStream != nil );
    
    P2PNodeConnection *connection = [[P2PNodeConnection alloc] initWithInputStream:inStream outputStream:outStream];
    connection.delegate = self;
    
    if ( self.activeConnections == nil )
    {
        self.activeConnections = [[NSMutableSet alloc] init];
    }
    [self.activeConnections addObject:connection];
    
    [connection openConnection];
}



#pragma mark - Object Transmission
- (void)transmitObject:(P2PTransmittableObject *)transmittableObject
{
    [self transmitObject:transmittableObject toNodeConnection:nil];
}

- (void)transmitObject:(P2PTransmittableObject *)transmittableObject toNodeConnection:(P2PNodeConnection *)connection;
{
    if ( connection == nil && [self.activeConnections count] == 1 )
    {
        connection = [self.activeConnections anyObject];
    }
    
    // If connection is still nil, we can't send this object
    if ( connection == nil )
    {
        [transmittableObject peer:self failedToSendObjectWithError:P2PTransmissionErrorPeerNoLongerReady];
    }
    else
    {
        // Serialize data... Add header and footer to the transmission
        NSData *preparedData = [self prepareObjectForTransmission:transmittableObject];
        [connection sendDataToConnection:preparedData];
        [transmittableObject peerDidBeginToSendObject:self];
    }
}


/** Serializes an object to be sent to another peer.  Adds header and footer information to the binary data
 
 Packet format:
 32-bit file size (file_size_type)
 archived object
 32-bit checksum (crc_type)
 */
- (NSData *)prepareObjectForTransmission:(id<NSCoding>)object
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    file_size_type fileSize = (file_size_type)[objectData length];
    crc_type crc = (crc_type) crc32( 0, [objectData bytes], (uInt)[objectData length] );
    
    // Combine the pieces
    NSMutableData *combinedData = [[NSMutableData alloc] initWithCapacity:sizeof( fileSize ) + [objectData length] + sizeof( crc )];
    [combinedData appendBytes:&fileSize length:sizeof( fileSize )];
    [combinedData appendBytes:[objectData bytes] length:[objectData length]];
    [combinedData appendBytes:&crc length:sizeof( crc )];
    
    return combinedData;
}




#pragma mark - P2PNodeConnectionDelegate Methods
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
    [self.activeConnections removeObject:node];
    P2PLog( P2PLogLevelWarning, @"%@ - connection lost: %@", self, node);
}



#pragma mark - Misc
- (void)cleanup
{
    for ( P2PNodeConnection *connection in self.activeConnections )
    {
        [connection dropConnection];
    }
    self.activeConnections = nil;
}

@end

