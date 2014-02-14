//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"
#import "P2PPeerFileAvailibilityRequest.h"

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

typedef NS_ENUM(NSUInteger, P2PNetworkToolHeaderPosition)
{
    P2PNetworkToolHeaderPositionNone = 0,
    P2PNetworkToolHeaderPositionType,
    P2PNetworkToolHeaderPositionSize,
    P2PNetworkToolHeaderPositionParity
};

static const NSUInteger P2PIncomingDataFileSizeUnknown = NSUIntegerMax;













/*
 Header/Data format
 
      size(bytes)    file
          |           |
 :00:000000000000:0:<data>
  |               |
 Type           parity
 
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


















/** This objected will handle incomming data to sort it out, make sure it is valid data, etc.
 
 After the download is complete, control of the input stream is automatically returned back to the
 calling calling object (presumably an instance of P2PNode).  This class will inform the delegate that the download
 is complete and the data is now available.
 
 */
// Private class
@interface P2PIncomingData : NSObject <NSStreamDelegate>

@property (weak, nonatomic) NSNetService *service;                   // The netservice that owns this downloads stream
@property (nonatomic, readonly) NSUInteger fileSize;
@property (readonly, nonatomic) P2PIncomingDataStatus status;
@property (weak, nonatomic) id<P2PIncomingDataDelegate> delegate;
@property (weak, nonatomic) NSInputStream *stream;
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
    P2PNetworkToolHeaderPosition _placeInHeader;
    
    uint8_t _parity;
}

- (id)init
{
    return [self initWithInputStream:nil forService:nil];
}

- (id)initWithInputStream:(NSInputStream *)stream forService:(NSNetService *)service
{
    assert( stream != nil );
    assert( service != nil );
    if ( self = [super init] )
    {
        _stream = stream;
        _service = service;
        _status = P2PIncomingDataStatusNotStarted;
        _fileSize = P2PIncomingDataFileSizeUnknown;
    }
    return self;
}

- (void)takeOverStream
{
    if ( _status == P2PIncomingDataStatusNotStarted )
    {
        _status = P2PIncomingDataStatusStarting;
        _stream.delegate = self;
        [self readFromStream];
    }
}

#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSAssert(aStream == _stream, @"We shouldn't be recieving callbacks for streams that aren't ours!");
    
    
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
            [self readFromStream];
            break;
        case NSStreamEventEndEncountered:
            P2PLogDebug(@"SERVER NSStreamEventEndEncountered");
            //[self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
            P2PLogDebug(@"SERVER %@ NSStreamEventHasSpaceAvailable", aStream);
            //            [self workOutputBuffer];
            break;
        case NSStreamEventErrorOccurred:
            P2PLogDebug(@"SERVER NSStreamEventErrorOccurred");
            break;
        case NSStreamEventOpenCompleted:
            P2PLogDebug(@"SERVER %@ NSStreamEventOpenCompleted", aStream);
            break;
        case NSStreamEventNone:
            P2PLogDebug(@"SERVER NSStreamEventNone");
        default:
            break;
    }
    
}

- (void)readFromStream
{
    if ( _stream.hasBytesAvailable )
    {
        // Setup (if needed)
        if ( _buffer == nil )
        {
            _buffer = [[NSMutableData alloc] initWithCapacity:2048];
        }
        
        if ( _status == P2PIncomingDataStatusStarting )
        {
            _status = P2PIncomingDataStatusReadingHeader;
            _placeInHeader = P2PNetworkToolHeaderPositionNone;
        }
        
        uint8_t oneByte;
        NSInteger actuallyRead = 0;
        
        
        
        // Read from buffer
        actuallyRead = [_stream read:&oneByte maxLength:1];
        
        
        //        NSLog(@"byte: %c", oneByte);
        if ( _status == P2PIncomingDataStatusReadingHeader )
        {
            if ( _placeInHeader == P2PNetworkToolHeaderPositionNone )
            {
                NSAssert( oneByte == ':', @"Invalid beginning of header");
                _placeInHeader = P2PNetworkToolHeaderPositionType;
            }
            else if ( _placeInHeader == P2PNetworkToolHeaderPositionType )
            {
                
                // :00:000000000000:0:<data>
                
                // Start reading the type
                NSAssert( !(_buffer.length == 0 && oneByte == ':'), @"Unexpected end of type" );
                
                if ( oneByte == ':' )
                {
                    // End of type block
                    uint8_t *b = (uint8_t *)[_buffer bytes];
                    _type = *b;
                    
                    _placeInHeader = P2PNetworkToolHeaderPositionSize;
                    _buffer.length = 0;
                }
                else
                {
                    // Keep appending bytes
                    [_buffer appendBytes:&oneByte length:1];
                }
            }
            else if ( _placeInHeader == P2PNetworkToolHeaderPositionSize )
            {
                NSAssert( !(_buffer.length == 0 && oneByte == ':'), @"Unexpected end of size" );
                
                if ( oneByte == ':' )
                {
                    // End of size block
                    NSUInteger *b = (NSUInteger *)[_buffer bytes];
                    _fileSize = *b;
                    
                    _placeInHeader = P2PNetworkToolHeaderPositionParity;
                    _buffer.length = 0;
                }
                else
                {
                    // Keep appending bytes
                    [_buffer appendBytes:&oneByte length:1];
                }
            }
            else if ( _placeInHeader == P2PNetworkToolHeaderPositionParity )
            {
                NSAssert( !(_buffer.length == 0 && oneByte == ':'), @"Unexpected end of parity" );
                
                if ( oneByte == ':' )
                {
                    // End of parity block
                    uint8_t *b = (uint8_t *)[_buffer bytes];
                    _parity = *b;
                    
                    _placeInHeader = P2PNetworkToolHeaderPositionNone;
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

- (void)dataDownloadDidFinish
{
    P2PLogDebug(@"%@ did finish downloading", self);
    _status = P2PIncomingDataStatusFinished;
    
    // Move our buffered data over to the publicly available property
    _downloadedData = _buffer;
    _buffer = nil;
    
    // Return control of the stream to our delegate.
    // For the intents of this P2P demo, we're going to assume that our delegate also
    // implements the NSStreamDelegate protocol...
    _stream.delegate = (id<NSStreamDelegate>)self.delegate;
    
    [self.delegate dataDidFinishLoading:self];
}

@end



















// Private Class
@interface P2PNodeConnction : NSObject
@property (weak, nonatomic) NSNetService *netService;

@property (weak, nonatomic) NSInputStream *inStream;
@property (strong, nonatomic) NSMutableData *inBuffer;

@property (weak, nonatomic) NSOutputStream *outStream;
@property (strong, nonatomic) NSMutableData *outBuffer;
@end

@implementation P2PNodeConnction

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

@end



















@interface P2PNode()<P2PIncomingDataDelegate>

@end

@implementation P2PNode
{
//    NSMutableData *_inStreamBuffer;
    
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
    if (bytesWritten > 0)
    {
        P2PLogDebug(@"%@ - Cleared output buffer for stream", self);
    }
    buffer.length = 0;
    
}

- (void)transmitObject:(id<NSCoding>)object
{
    NSAssert( [_activeConnections count] == 1, @"A server must specify what service to send the object to with transmitObject:toNetService:" );
    [self transmitObject:object toNetService:nil];
}

- (void)transmitObject:(id<NSCoding>)object toNetService:(NSNetService *)service
{
    NSData *preparedData = prepareObjectForTransmission( object );
    
    P2PNodeConnction *connection = [self connectionForNetService:service];
    assert( connection != nil );
    
    // Add data to buffer
    [connection.outBuffer appendData:preparedData];

    [self workOutputBufferForStream:connection.outStream buffer:connection.outBuffer];
}

#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
        {
            P2PLogDebug(@"%@ - NSStreamEventHasBytesAvailable", self);
            
            assert([aStream isKindOfClass:[NSInputStream class]]);

            P2PIncomingData *d = [[P2PIncomingData alloc] initWithInputStream:((NSInputStream *)aStream) forService:[self netServiceForStream:aStream]];
            
            if ( _activeDataTransfers == nil )
            {
                _activeDataTransfers = [[NSMutableArray alloc] init];
            }
            
            [_activeDataTransfers addObject:d];
            d.delegate = self;
            [d takeOverStream];
            
            break;
        }
        case NSStreamEventEndEncountered:
        {
            P2PLogDebug(@"%@ - NSStreamEventEndEncountered", self);
            //[self closeStreams];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            P2PLogDebug(@"%@ - %@ NSStreamEventHasSpaceAvailable", self, aStream);
            assert( [aStream isKindOfClass:[NSOutputStream class]] );
            
            [self workOutputBufferForStream:(NSOutputStream *)aStream buffer:[self bufferForStream:aStream]];
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            P2PLogDebug(@"%@ - NSStreamEventErrorOccurred", self);
            break;
        }
        case NSStreamEventOpenCompleted:
        {
            P2PLogDebug(@"%@ - %@ NSStreamEventOpenCompleted", self, aStream);
            break;
        }
        case NSStreamEventNone:
        {
            P2PLogDebug(@"%@ - NSStreamEventNone", self);
        }
        default:
            break;
    }
}

- (NSNetService *)netServiceForStream:(NSStream *)stream
{
    for ( P2PNodeConnction *c in _activeConnections )
    {
        if ( c.inStream == stream || c.outStream == stream )
        {
            return c.netService;
        }
    }
    return nil;
}

- (NSMutableData *)bufferForStream:(NSStream *)stream
{
    for ( P2PNodeConnction *c in _activeConnections )
    {
        if ( c.inStream == stream )
        {
            return c.inBuffer;
        }
        if ( c.outStream == stream )
        {
            return c.outBuffer;
        }
    }
    return nil;
}

- (P2PNodeConnction *)connectionForNetService:(NSNetService *)service
{
    // if nil is specified for service, we just return the first service
    if ( service == nil )
    {
        assert( [_activeConnections count] == 1 );
        return [_activeConnections objectAtIndex:0];
    }
    
    for ( P2PNodeConnction *c in _activeConnections )
    {
        if ( c.netService == service )
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
            P2PLogDebug(@"%@ - recieved object: %@", self, obj);
            [self handleRecievedObject:obj from:loader.service];
            break;
        }
        case P2PNetworkTransmissionTypeData:
        case P2PNetworkTransmissionTypeUnknown:
        default:
            NSAssert(NO, @"Unknown file recieved");
            break;
    }
}

/** If we have an incoming object from a data transfer, it will be sent here so we can figure out
 what to do with it */
- (void)handleRecievedObject:(id)object from:(NSNetService *)sender
{
    NSAssert([self class] != [P2PNode class], @"This selector should be overridden by subclasses");
}

- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream forService:(NSNetService *)service
{
    assert( inStream != nil );
    assert( outStream != nil );
    assert( service != nil );
    
    P2PNodeConnction *connection = [[P2PNodeConnction alloc] init];
    connection.inStream = inStream;
    connection.outStream = outStream;
    connection.netService = service;
    
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


@end

