//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"
#import "P2PPeerFileAvailibilityRequest.h"

#import "P2PIncomingData.h"
#import "P2PNodeConnection.h"

/** Since the peer and server will share a lot of the same functionality,
 I decided to go ahead and just make them children of this superclass.  */

@interface P2PNode() <P2PIncomingDataDelegate>

@end

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

- (void)workOutputBufferForStream:(NSOutputStream *)stream buffer:(NSMutableData *)buffer
{
    assert(buffer != nil);
    assert(stream != nil);
    
    
    NSInteger bytesWritten = 0;
    while ( buffer.length > bytesWritten )
    {
        if ( ! stream.hasSpaceAvailable )
        {
            // If we're here, the buffer is full.  We should get an NSStreamEventHasSpaceAvailable event
            // soon, and then we'll call this method again.
            
            
            // Remove what we were able to write from the buffer.  This is a bad (slow) way of doing it though
            // Will have to replace this with a higher-performance method in the future
            P2PLogDebug(@"%@ - out buffer full... waiting... ", self);
            [buffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
            return;
        }
        
        //sending NSData over to server
        NSInteger writeResult = [stream write:[buffer bytes] + bytesWritten
                                    maxLength:[buffer length] - bytesWritten];
        
        if ( writeResult == -1 )
            P2PLog( P2PLogLevelError, @"Failed to write to output stream: %@", stream );
        else
        {
            bytesWritten += writeResult;
        }
    }
    buffer.length = 0;
    P2PLogDebug(@"%@ - Finished working output buffer", self);
    
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
        
        // Add the binary data to buffer
        [connection.outBuffer appendData:preparedData];

        P2PLogDebug( @"%@ - sending object: %@ to %@", self, transmittableObject, connection );
        [self workOutputBufferForStream:connection.outStream buffer:connection.outBuffer];
        [transmittableObject peerDidBeginToSendObject:self];
    }
}

- (void)objectDidFailToSend:(id)object
{
    NSAssert([self class] != [P2PNode class], @"This selector should be overridden by subclasses");
}

#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    P2PNodeConnection *connection = [self connectionNodeForStream:aStream];
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
        {
            if ( connection != nil )
            {
                assert([aStream isKindOfClass:[NSInputStream class]]);
                P2PIncomingData *d = [[P2PIncomingData alloc] initWithConnection:connection];
                d.delegate = self;
                
                if ( _activeDataTransfers == nil )
                {
                    _activeDataTransfers = [[NSMutableSet alloc] init];
                }
                
                [_activeDataTransfers addObject:d];
                [d startDownloadingData];
            }
            else
            {
                P2PLog( P2PLogLevelError, @"Could not take over stream: %@ - No matching P2PNodeConnection object", aStream );
            }
            
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            P2PLog( P2PLogLevelWarning, @"Error occured in stream: %@ (%@) for %@", aStream, [aStream streamError], self );
            break;
        }
        case NSStreamEventEndEncountered:
        {
            [self connectionDidEnd:connection];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            assert( [aStream isKindOfClass:[NSOutputStream class]] );
            
            P2PNodeConnection *connection = [self connectionNodeForStream:aStream];
            assert( connection != nil );
            
            [self workOutputBufferForStream:(NSOutputStream *)aStream buffer:connection.outBuffer];
            break;
        }
        case NSStreamEventOpenCompleted:
        case NSStreamEventNone:
        default:
            break;
    }
}

- (P2PNodeConnection *)connectionNodeForStream:(NSStream *)stream
{
    // if nil is specified for stream, we just return the first node
    if ( stream == nil )
    {
        assert( [_activeConnections count] == 1 );
        return [_activeConnections anyObject];
    }
    
    for ( P2PNodeConnection *c in _activeConnections )
    {
        if ( c.inStream == stream || c.outStream == stream )
        {
            return c;
        }
    }
    return nil;
}


#pragma mark - P2PIncomingDataDelegate
- (void)dataDidFinishLoading:(P2PIncomingData *)loader
{
    [_activeDataTransfers removeObject:loader];

    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:loader.downloadedData];
    P2PLogDebug(@"%@ - recieved object: %@ from %@", self, obj, loader.connection);

	[self handleReceivedObject:obj from:loader.connection];
}

- (void)dataFailedToDownload:(P2PIncomingData *)loader
{
    [_activeDataTransfers removeObject:loader];
    switch ( loader.errorCode )
    {
        case P2PIncomingDataErrorCodeNoData:
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: NO DATA", loader );
            break;
        case P2PIncomingDataErrorCodeStreamEnded:
        {
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: Stream ended", loader );
            [self connectionDidEnd:loader.connection];
            break;
        }
        case P2PIncomingDataErrorCodeStreamError:
        {
            P2PLog( P2PLogLevelWarning, @"%@ - failed with error: Error with stream", loader );
            break;
        }
        default:
            break;
    }
}

/** If we have an incoming object from a data transfer, it will be sent here so we can figure out
 what to do with it */
- (void)handleReceivedObject:(id)object from:(P2PNodeConnection *)sender
{
    NSAssert([self class] != [P2PNode class], @"This selector should be overridden by subclasses");
}

- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream
{
    assert( inStream != nil );
    assert( outStream != nil );
    
    P2PNodeConnection *connection = [[P2PNodeConnection alloc] init];
    connection.inStream = inStream;
    connection.outStream = outStream;
    
    if ( _activeConnections == nil )
    {
        _activeConnections = [[NSMutableSet alloc] init];
    }
    [_activeConnections addObject:connection];
    
    
    inStream.delegate = self;
    [inStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [inStream open];
    
    outStream.delegate = self;
    [outStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream open];
}

- (void)connectionDidEnd:(P2PNodeConnection *)node
{
    [_activeConnections removeObject:node];
    P2PLog( P2PLogLevelWarning, @"%@ - connection lost: %@", self, node);
}

- (void)cleanup
{
    for ( P2PNodeConnection *connection in _activeConnections )
    {
        [connection.inStream close];
        [connection.outStream close];
    }
}

@end

