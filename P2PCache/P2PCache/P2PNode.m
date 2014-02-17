//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"
#import "P2PPeerFileAvailibilityRequest.h"

/** Since the peer and server will share a lot of the same functionality,
 I decided to go ahead and just make them children of this superclass.
 
 All of the common networking tools will be found here */

@class P2PIncomingData;
@protocol P2PIncomingDataDelegate <NSObject>

- (void)dataDidFinishLoading:(P2PIncomingData *)loader;
- (void)dataFailedToDownload:(P2PIncomingData *)loader;

@end

typedef NS_ENUM(uint8_t, P2PNetworkTransmissionType)
{
    P2PNetworkTransmissionTypeUnknown = 0,
    P2PNetworkTransmissionTypeObject,
    P2PNetworkTransmissionTypeData
};

typedef NS_ENUM(NSUInteger, P2PIncomingDataStatus)
{
    P2PIncomingDataStatusNotStarted = 0,
    P2PIncomingDataStatusStarting,
    P2PIncomingDataStatusReadingHeader,
    P2PIncomingDataStatusReadingData,
    P2PIncomingDataStatusFinished,
    P2PIncomingDataStatusError
};

typedef NS_ENUM(NSUInteger, P2PIncomingDataErrorCode)
{
    P2PIncomingDataErrorCodeNoError = 0,    // There is no error
    P2PIncomingDataErrorCodeNoData,         // For some reason we just recieved a NULL character... still trying to figure out why this happens...
    P2PIncomingDataErrorCodeInvalidHeader,  // Something about the header was off on the transmission
    P2PIncomingDataErrorCodeStreamEnded,    // The peer disconnected in the middle of the transmission
    P2PIncomingDataErrorCodeStreamError     // An error occoured in the stream... connection probably dropped
};

typedef NS_ENUM(NSUInteger, P2PIncomingDataHeaderPosition)
{
    P2PIncomingDataHeaderPositionNone = 0,
    P2PIncomingDataHeaderPositionType,
    P2PIncomingDataHeaderPositionSize,
    P2PIncomingDataHeaderPositionParity
};

static const NSUInteger P2PIncomingDataFileSizeUnknown = NSUIntegerMax;

/*
 Header/Data format
 
     size(bytes)    file
         |           |
 :00:000000000000:0:<data>
   |              |
  Type          parity
 
 Type:   The type of data that is about to be transmitted (P2PNetworkTransmissionType)
 Size:   The size in bytes of the data that is about to be transmitted
 Parity: Parity bit for the data to verify after recieving
 Data:   The binary data
 
 */

uint8_t computeParityBit( NSData *data )
{
    return 0; // TODO
}

NSData* prepareTransmission( NSData *dataToTransmit, P2PNetworkTransmissionType dataType )
{
    NSMutableData *compositeData = [[NSMutableData alloc] init];
    
    // Seperator between information
    const char seperator = ':';
    
    // Initial seperator
    [compositeData appendBytes:&seperator length:sizeof( seperator )];
    
    // Data type flag
    [compositeData appendBytes:&dataType length:sizeof( dataType )];
    
    // Seperator
    [compositeData appendBytes:&seperator length:sizeof( seperator )];
    
    // File size
    NSUInteger size = dataToTransmit.length;
    [compositeData appendBytes:&size length:sizeof( size )];
    
    // Seperator
    [compositeData appendBytes:&seperator length:sizeof( seperator )];
    
    // Parity bit
    uint8_t p = computeParityBit( dataToTransmit );
    [compositeData appendBytes:&p length:sizeof( p )];
    
    // Seperator
    [compositeData appendBytes:&seperator length:sizeof( seperator )];
    
    // Append data to the header
    [compositeData appendData:dataToTransmit];
    
    return compositeData;
}

NSData* prepareObjectForTransmission( id<NSCoding> object )
{
    return prepareTransmission( [NSKeyedArchiver archivedDataWithRootObject:object], P2PNetworkTransmissionTypeObject );
}

NSData* prepareDataForTransmission( NSData *dataToTransmit )
{
    return prepareTransmission( dataToTransmit, P2PNetworkTransmissionTypeData );
}












/** Represents a connection between two nodes.  Contains the connection ID, both I/O streams, and buffers */
@interface P2PNodeConnection : NSObject
@property (nonatomic, readonly) NSUInteger connectionId;

@property (weak, nonatomic) NSInputStream *inStream;
@property (strong, nonatomic) NSMutableData *inBuffer;

@property (weak, nonatomic) NSOutputStream *outStream;
@property (strong, nonatomic) NSMutableData *outBuffer;
@end

@implementation P2PNodeConnection

static NSUInteger currentConnectionId = 1;
- (id)init
{
    if ( self = [super init] )
    {
        _connectionId = currentConnectionId++;
    }
    return self;
}

- (NSMutableData *)inBuffer
{
    if ( _inBuffer == nil)
    {
        _inBuffer = [[NSMutableData alloc] initWithCapacity:2048];
    }
    return _inBuffer;
}

- (NSMutableData *)outBuffer
{
    if ( _outBuffer == nil )
    {
        _outBuffer = [[NSMutableData alloc] initWithCapacity:2048];
    }
    return _outBuffer;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ - ID: %lu>", [self class], (unsigned long)_connectionId];
}

@end











/** This objecte will handle incomming data to sort it out, make sure it is valid data, etc.
 
 After the download is complete, control of the input stream is automatically returned back to the
 calling calling object (presumably an instance of P2PNode).  This class will inform the delegate that the download
 is complete and the data is now available.
 
 */
@interface P2PIncomingData : NSObject <NSStreamDelegate>

@property (weak, nonatomic, readonly) P2PNodeConnection *connection;
@property (nonatomic, readonly) NSUInteger fileSize;

@property (readonly, nonatomic) P2PIncomingDataStatus status;
@property (readonly, nonatomic) P2PIncomingDataErrorCode errorCode;

@property (weak, nonatomic) id<P2PIncomingDataDelegate> delegate;
@property (strong, nonatomic, readonly) id downloadedData;          // Downloaded data may either be an object (such as a request)
@property (readonly, nonatomic) P2PNetworkTransmissionType type;    // Or a binary data file
                                                                    // The correct one can be found by using the type property
                                                                    // well, now that i think about it, it will probably always be an object,
                                                                    // because a binary file will be wrapped in a P2PFileChunk object
                                                                    // so..... we'll come back to this

@end

@implementation P2PIncomingData
{
    NSMutableData *_buffer;
    P2PIncomingDataHeaderPosition _placeInHeader;
    
    uint8_t _parity;
}

- (id)init
{
    return [self initWithConnection:nil];
}

- (id)initWithConnection:(P2PNodeConnection *)connection
{
    assert( connection != nil );
    if ( self = [super init] )
    {
        _connection = connection;
        _status = P2PIncomingDataStatusNotStarted;
        _errorCode = P2PIncomingDataErrorCodeNoError;
        _fileSize = P2PIncomingDataFileSizeUnknown;
    }
    return self;
}

- (void)takeOverStream
{
    if ( _status == P2PIncomingDataStatusNotStarted )
    {
        _status = P2PIncomingDataStatusStarting;
        _connection.inStream.delegate = self;
        [self readFromStream];
    }
}

#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSAssert(aStream == _connection.inStream, @"We shouldn't be recieving callbacks for streams that aren't ours!");
    
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
            [self readFromStream];
            break;
        case NSStreamEventEndEncountered:
            [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeStreamEnded];
            break;
        case NSStreamEventErrorOccurred:
            [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeStreamError];
            break;
        case NSStreamEventHasSpaceAvailable:
        case NSStreamEventOpenCompleted:
        case NSStreamEventNone:
        default:
            break;
    }
    
}

- (void)readFromStream
{
    if ( _connection.inStream.hasBytesAvailable )
    {
        // Setup (if needed)
        if ( _buffer == nil )
        {
            _buffer = [[NSMutableData alloc] initWithCapacity:2048];
        }
        
        if ( _status == P2PIncomingDataStatusStarting )
        {
            _status = P2PIncomingDataStatusReadingHeader;
            _placeInHeader = P2PIncomingDataHeaderPositionNone;
        }
        
        uint8_t oneByte;
        NSInteger actuallyRead = 0;
        
        // Read from buffer
        actuallyRead = [_connection.inStream read:&oneByte maxLength:1];

        if ( _status == P2PIncomingDataStatusReadingHeader )
        {
            if ( _placeInHeader == P2PIncomingDataHeaderPositionNone )
            {
                if ( oneByte != ':' )
                {
                    // For some reason we are getting a "null" character as soon
                    // as we connect to a peer.
                    // I suppose for now we will just ignore this and
                    // cancel this download object
                    [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeInvalidHeader];
                    return;
                }
//                NSAssert( oneByte == ':', @"Invalid beginning of header");
                _placeInHeader = P2PIncomingDataHeaderPositionType;
            }
            else if ( _placeInHeader == P2PIncomingDataHeaderPositionType )
            {
                // Start reading the type
//                NSAssert( !(_buffer.length == 0 && oneByte == ':'), @"Unexpected end of type" );
                if ( _buffer.length == 0 && oneByte == ':' )
                {
                    // The type section ended without supplying any data
                    [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeInvalidHeader];
                    return;
                }
                
                if ( oneByte == ':' )
                {
                    // End of type block
                    uint8_t *b = (uint8_t *)[_buffer bytes];
                    _type = *b;
                    
                    _placeInHeader = P2PIncomingDataHeaderPositionSize;
                    _buffer.length = 0;
                }
                else
                {
                    // Keep appending bytes
                    [_buffer appendBytes:&oneByte length:1];
                }
            }
            else if ( _placeInHeader == P2PIncomingDataHeaderPositionSize )
            {
//                NSAssert( !(_buffer.length == 0 && oneByte == ':'), @"Unexpected end of size" );
                if ( _buffer.length == 0 && oneByte == ':' )
                {
                    // The type section ended without supplying any data
                    [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeInvalidHeader];
                    return;
                }
                
                if ( oneByte == ':' )
                {
                    // End of size block
                    NSUInteger *b = (NSUInteger *)[_buffer bytes];
                    _fileSize = *b;
                    
                    _placeInHeader = P2PIncomingDataHeaderPositionParity;
                    _buffer.length = 0;
                }
                else
                {
                    // Keep appending bytes
                    [_buffer appendBytes:&oneByte length:1];
                }
            }
            else if ( _placeInHeader == P2PIncomingDataHeaderPositionParity )
            {
//                NSAssert( !(_buffer.length == 0 && oneByte == ':'), @"Unexpected end of parity" );
                if ( _buffer.length == 0 && oneByte == ':' )
                {
                    // The type section ended without supplying any data
                    [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeInvalidHeader];
                    return;
                }
                
                if ( oneByte == ':' )
                {
                    // End of parity block
                    uint8_t *b = (uint8_t *)[_buffer bytes];
                    _parity = *b;
                    
                    _placeInHeader = P2PIncomingDataHeaderPositionNone;
                    _buffer.length = 0;
                    
                    // End of header.  We can start reading data now
                    _status = P2PIncomingDataStatusReadingData;
                }
                else
                {
                    // Keep appending bytes
                    [_buffer appendBytes:&oneByte length:1];
                }
            }
        }
        else if ( _status == P2PIncomingDataStatusReadingData )
        {
            [_buffer appendBytes:&oneByte length:1];
            
            if ( [_buffer length] == _fileSize )
            {
                // Data has been recieved
                [self dataDownloadDidFinish];
            }
        }
    }
}

- (void)dataDownloadFailedWithError:(P2PIncomingDataErrorCode)errorCode
{
    _status = P2PIncomingDataStatusError;
    _errorCode = errorCode;
    _downloadedData = nil;
    _buffer = nil;
    [self returnControlToSender];
    [self.delegate dataFailedToDownload:self];
}

- (void)dataDownloadDidFinish
{
    _status = P2PIncomingDataStatusFinished;
    
    // Move our buffered data over to the publicly available property
    _downloadedData = _buffer;
    _buffer = nil;
    
    [self returnControlToSender];
    [self.delegate dataDidFinishLoading:self];
}

- (void)returnControlToSender
{
    // Return control of the stream to our delegate.
    // For the intents of this P2P demo, we're going to assume that our delegate also
    // implements the NSStreamDelegate protocol...
    _connection.inStream.delegate = (id<NSStreamDelegate>)self.delegate;
}

@end









@interface P2PNode() <P2PIncomingDataDelegate>

@end

@implementation P2PNode
{
    NSMutableArray *_activeConnections;     // An array of active P2PNodeConnection objects
    NSMutableArray *_activeDataTransfers;   // An array of P2PIncomingData objects
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
    
}

- (void)transmitObject:(id<NSCoding>)object
{
    [self transmitObject:object toNodeConnection:nil];
}

- (void)objectDidFailToSend:(id)object
{
    NSAssert([self class] != [P2PNode class], @"This selector should be overridden by subclasses");
}

- (void)transmitObject:(id<NSCoding>)object toNodeConnection:(P2PNodeConnection *)connection
{
    NSData *preparedData = prepareObjectForTransmission( object );
    
    if ( connection == nil && [_activeConnections count] == 1 )
    {
        connection = [_activeConnections objectAtIndex:0];
    }
    NSAssert( connection != nil, @"Ambigious connection.  A node connection must be specified to send an object to" );
    
    // Add data to buffer
    [connection.outBuffer appendData:preparedData];

    P2PLogDebug( @"%@ - sending object: %@ to %@", self, object, connection );
    [self workOutputBufferForStream:connection.outStream buffer:connection.outBuffer];
}

#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    P2PNodeConnection *connection = [self connectionNodeForStream:aStream];
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
        {
            assert([aStream isKindOfClass:[NSInputStream class]]);

            P2PIncomingData *d = [[P2PIncomingData alloc] initWithConnection:connection];
            
            if ( _activeDataTransfers == nil )
            {
                _activeDataTransfers = [[NSMutableArray alloc] init];
            }
            
            [_activeDataTransfers addObject:d];
            d.delegate = self;
            [d takeOverStream];
            
            break;
        }
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered:
        {
            [self connection:connection failedWithStreamError:NSStreamEventEndEncountered];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            assert( [aStream isKindOfClass:[NSOutputStream class]] );
            P2PNodeConnection *connection = [self connectionNodeForStream:aStream];
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
        return [_activeConnections objectAtIndex:0];
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
    
    switch ( loader.type )
    {
        case P2PNetworkTransmissionTypeObject:
        {
            id obj = [NSKeyedUnarchiver unarchiveObjectWithData:loader.downloadedData];
            P2PLogDebug(@"%@ - recieved object: %@ from %@", self, obj, loader.connection);
            [self handleRecievedObject:obj from:loader.connection];
            break;
        }
        case P2PNetworkTransmissionTypeData:
        case P2PNetworkTransmissionTypeUnknown:
        default:
            NSAssert(NO, @"Unknown file recieved");
            break;
    }
    
//    [self objectDidFailToSend:loader.]
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
            [self connection:loader.connection failedWithStreamError:NSStreamEventEndEncountered];
            break;
        case P2PIncomingDataErrorCodeStreamError:
            [self connection:loader.connection failedWithStreamError:NSStreamEventErrorOccurred];
            break;
        default:
            break;
    }
}

/** If we have an incoming object from a data transfer, it will be sent here so we can figure out
 what to do with it */
- (void)handleRecievedObject:(id)object from:(P2PNodeConnection *)sender
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
        _activeConnections = [[NSMutableArray alloc] init];
    }
    [_activeConnections addObject:connection];
    
    
    inStream.delegate = self;
    [inStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [inStream open];
    
    outStream.delegate = self;
    [outStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream open];
}

- (void)connection:(P2PNodeConnection *)node failedWithStreamError:(NSStreamEvent)errorEvent
{
    [_activeConnections removeObject:node];
    P2PLog( P2PLogLevelWarning, @"%@ - connection lost: %@", self, node);
}

- (void)cleanup
{
    [super cleanup];
    for ( P2PNodeConnection *connection in _activeConnections )
    {
        [connection.inStream close];
        [connection.outStream close];
    }
}

@end

