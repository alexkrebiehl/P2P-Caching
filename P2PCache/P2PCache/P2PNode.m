//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"
#import "P2PPeerFileAvailibilityRequest.h"


NSData* prepareObjectForTransmission( id<NSCoding> object );

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
    NSMutableData *_inStreamBuffer;
    
    NSMutableArray *_activeConnections;
    
    NSMutableArray *_activeDataTransfers;   // An array of P2PIncomingData objects
}


- (void)workOutputBufferForStream:(NSOutputStream *)stream buffer:(NSMutableData *)buffer
{
    assert(buffer != nil);
    assert(stream != nil);
    
    
    NSInteger bytesWritten = 0;
    while ( buffer.length > bytesWritten )
    {
        NSLog(@"working buffer");
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
            NSLog(@"error code here");
        else
        {
            bytesWritten += writeResult;
            NSLog(@"wrote %ld bytes to buffer", (long)writeResult );
        }
        
        
    }
    NSLog(@"finished transmitting data to peer");
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
//    if ( [data conformsToProtocol:@protocol( NSCoding )] )
//    {
//        preparedData = prepareObjectForTransmission( data );
//    }
//    else if ( [data isMemberOfClass:[NSData class]] )
//    {
//        preparedData = prepareDataForTransmission( data );
//    }
//    else
//    {
//        NSAssert( NO, @"object must be NSData or implement NSCoding");
//    }
    
    P2PNodeConnction *connection = [self connectionForNetService:service];
    assert( connection != nil );
    
//    if ( _outStreamBuffer == nil )
//    {
//        _outStreamBuffer = [[NSMutableData alloc] initWithCapacity:preparedData.length];
//    }
    
    
    
    
    // Add data to buffer
    [connection.outBuffer appendData:preparedData];
    
//    NSLog(@"sending: %@", _outStreamBuffer);
    
    [self workOutputBufferForStream:connection.outStream buffer:connection.outBuffer];
}






#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
        {
            NSLog(@"SERVER NSStreamEventHasBytesAvailable");
            
            assert([aStream isKindOfClass:[NSInputStream class]]);
            P2PIncomingData *d = [[P2PIncomingData alloc] initWithInputStream:((NSInputStream *)aStream)];
            
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
            NSLog(@"SERVER NSStreamEventEndEncountered");
            //[self closeStreams];
            break;
        }
        case NSStreamEventHasSpaceAvailable:
        {
            NSLog(@"SERVER %@ NSStreamEventHasSpaceAvailable", aStream);
            assert( [aStream isKindOfClass:[NSOutputStream class]] );
            
            [self workOutputBufferForStream:(NSOutputStream *)aStream buffer:[self bufferForStream:aStream]];
            break;
        }
        case NSStreamEventErrorOccurred:
        {
            NSLog(@"SERVER NSStreamEventErrorOccurred");
            break;
        }
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"SERVER %@ NSStreamEventOpenCompleted", aStream);
            break;
        }
        case NSStreamEventNone:
        {
            NSLog(@"SERVER NSStreamEventNone");
        }
        default:
            break;
    }
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
    NSLog(@"download finished: %@", loader );
    [_activeDataTransfers removeObject:loader];
    
    
    switch ( loader.type )
    {
        case P2PNetworkTransmissionTypeObject:
        {
            id obj = [NSKeyedUnarchiver unarchiveObjectWithData:loader.downloadedData];
            NSLog(@"recieved object: %@", obj);
            [self handleRecievedObject:obj from:nil];
            break;
        }
        case P2PNetworkTransmissionTypeData:
            // fall through... not planning on having only-data transfers
            NSLog(@"recieved data: %@", loader.downloadedData);
        case P2PNetworkTransmissionTypeUnknown:
        default:
            NSAssert(NO, @"Unknown file recieved");
            break;
    }
}

/** If we have an incoming object from a data transfer, it will be sent here so we can figure out
 what to do with it */
- (void)handleRecievedObject:(id)object from:(P2PNode *)sender
{
    NSAssert([self class] != [P2PNode class], @"This selector should be overridden by subclasses");
}


- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream forService:(NSNetService *)service
{
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










/*
 Header/Data format: (23 bytes)
 
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


typedef NS_ENUM(NSUInteger, P2PNetworkToolHeaderPosition)
{
    P2PNetworkToolHeaderPositionNone = 0,
    P2PNetworkToolHeaderPositionType,
    P2PNetworkToolHeaderPositionSize,
    P2PNetworkToolHeaderPositionParity
};

//#import "P2PNetworkTool.h"

//void padWithZeros( int32_t *ptr, NSUInteger length, NSUInteger value )
//{
//    for ( NSUInteger i = length -1; i != 0; i-- )
//    {
//        NSUInteger nextVal = value / (i * 10);
//        ptr[i] = nextVal;
//    }
//}

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


/* Public functions */
NSData* prepareObjectForTransmission( id<NSCoding> object )
{
    return prepareTransmission( [NSKeyedArchiver archivedDataWithRootObject:object], P2PNetworkTransmissionTypeObject );
}

NSData* prepareDataForTransmission( NSData *dataToTransmit )
{
    return prepareTransmission( dataToTransmit, P2PNetworkTransmissionTypeData );
}










@implementation P2PIncomingData
{
    NSMutableData *_buffer;
    P2PNetworkToolHeaderPosition _placeInHeader;
    
    uint8_t _parity;
}

- (id)initWithInputStream:(NSInputStream *)stream
{
    if ( self = [super init] )
    {
        _stream = stream;
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
            NSLog(@"SERVER NSStreamEventEndEncountered");
            //[self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"SERVER %@ NSStreamEventHasSpaceAvailable", aStream);
            //            [self workOutputBuffer];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"SERVER NSStreamEventErrorOccurred");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"SERVER %@ NSStreamEventOpenCompleted", aStream);
            break;
        case NSStreamEventNone:
            NSLog(@"SERVER NSStreamEventNone");
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
        
        //
        //        const char *bytes = _inStreamBuffer.bytes;
        //        if ( oneByte == ':' && bytes[iLength - 1] == ':' && bytes[iLength - 2] == ':' )
        //        {
        //            //                NSLog(@"in buffer: %@", _inStreamBuffer);
        //            [_inStreamBuffer setLength:[_inStreamBuffer length] - 2]; // remove last 2 :'s
        //            id recievedObj = [NSKeyedUnarchiver unarchiveObjectWithData:_inStreamBuffer];
        //            NSLog(@"SERVER recieved data: %@", recievedObj);
        //            _inStreamBuffer = nil;
        //        }
        //        else if (actuallyRead == 1)
        //        {
        //
        //        }
    }
}

//- (void)processHeader
//{
//    NSAssert( _status == P2PIncomingDataStatusReadingHeader, @"This method should only be called when the buffer contains the header");
//
//
//    const char *bytes = [_buffer bytes];
//
//    bool isReadingType;
//
//    // ::00::000000000000::0::<data>
//
//    for ( int i = 0; i < _buffer.length; i++ )
//    {
//        uint8_t byte = bytes[i];
//
//        // byte 0 & 1 must be ::
//        NSAssert((i == 0 || i == 1) && byte != ':', @"Invalid beginning of header");
//
//
//    }
//
//    NSLog(@"Header: %@", nil);
//
//
//
//
//    _buffer.length = 0; // empty the buffer
//    _status = P2PIncomingDataStatusReadingData;
//}


- (void)dataDownloadDidFinish
{
    NSLog(@"%@ did finish downloading", self);
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

