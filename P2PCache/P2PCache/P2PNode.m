//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"
#import "P2PPeerFileAvailibilityRequest.h"
#import <zlib.h>

/** Since the peer and server will share a lot of the same functionality,
 I decided to go ahead and just make them children of this superclass.
 
 All of the common networking tools will be found here */


@class P2PIncomingData;
@protocol P2PIncomingDataDelegate <NSObject>

- (void)dataDidFinishLoading:(P2PIncomingData *)loader;
- (void)dataFailedToDownload:(P2PIncomingData *)loader;

@end

typedef NS_ENUM( NSUInteger, P2PIncomingDataStatus )
{
    P2PIncomingDataStatusNotStarted = 0,
    P2PIncomingDataStatusStarting,
    P2PIncomingDataStatusReadingHeader,
    P2PIncomingDataStatusReadingData,
    P2PIncomingDataStatusReadingFooter,
    P2PIncomingDataStatusFinished,
    P2PIncomingDataStatusError
};

typedef NS_ENUM( NSUInteger, P2PIncomingDataErrorCode )
{
    P2PIncomingDataErrorCodeNoError = 0,    // There is no error
    P2PIncomingDataErrorCodeNoData,         // For some reason we just recieved a NULL character... still trying to figure out why this happens...
    P2PIncomingDataErrorCodeInvalidHeader,  // Something about the header was off on the transmission
    P2PIncomingDataErrorCodeStreamEnded,    // The peer disconnected in the middle of the transmission
    P2PIncomingDataErrorCodeStreamError,    // An error occoured in the stream... connection probably dropped
    P2PIncomingDataErrorCodeCurruptFile     // Recieved file was currupt
};

enum
{
    P2PNodeConnectionBufferSize = 32 * 1024, // 32kb buffer
};

typedef uint32_t crc_type;

static const NSUInteger P2PIncomingDataFileSizeUnknown = NSUIntegerMax;

NSData* prepareObjectForTransmission( id<NSCoding> object )
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSUInteger fileSize = [objectData length];
    crc_type crc = (crc_type) crc32( 0, [objectData bytes], (uInt)[objectData length] );
    
    // Combine the pieces
    NSMutableData *combinedData = [NSMutableData dataWithCapacity:sizeof( fileSize ) + [objectData length] + sizeof( crc )];
    [combinedData appendBytes:&fileSize length:sizeof( fileSize )];
    [combinedData appendBytes:[objectData bytes] length:[objectData length]];
    [combinedData appendBytes:&crc length:sizeof( crc )];
    
    
    return combinedData;
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
{
    
}


NSUInteger getNextConnectionId()
{
    static NSUInteger nextId = 1;
    return nextId++;
}


- (id)init
{
    if ( self = [super init] )
    {
        _connectionId = getNextConnectionId();
    }
    return self;
}

- (NSMutableData *)inBuffer
{
    if ( _inBuffer == nil)
    {
        _inBuffer = [[NSMutableData alloc] initWithCapacity:P2PNodeConnectionBufferSize];
    }
    return _inBuffer;
}

- (NSMutableData *)outBuffer
{
    if ( _outBuffer == nil )
    {
        _outBuffer = [[NSMutableData alloc] initWithCapacity:P2PNodeConnectionBufferSize];
    }
    return _outBuffer;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ - ID: %lu>", [self class], (unsigned long)_connectionId];
}

@end











/** This object will handle incomming data to sort it out, make sure it is valid data, etc.
 
 After the download is complete, control of the input stream is automatically returned back to the
 calling calling object (presumably an instance of P2PNode).  This class will inform the delegate that the download
 is complete and the data is now available.
 
 Header/Data format
 
 
 New format:
 64-bit file size
 data
 32-bit checksum (crc_type)
 
 */
@interface P2PIncomingData : NSObject <NSStreamDelegate>

@property (weak, nonatomic, readonly) P2PNodeConnection *connection;
@property (nonatomic, readonly) NSUInteger fileSize;

@property (readonly, nonatomic) P2PIncomingDataStatus status;
@property (readonly, nonatomic) P2PIncomingDataErrorCode errorCode;

@property (weak, nonatomic) id<P2PIncomingDataDelegate> delegate;
@property (strong, nonatomic, readonly) NSData *downloadedData;

@end

@implementation P2PIncomingData
{
    NSMutableData *_buffer;
    NSUInteger _bufferOffset;
    NSUInteger _fileOffset;

    crc_type _crc;
    NSMutableData *_assembledData;
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
        _bufferOffset = 0;
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
            assert( NO );
            break;
    }
    
}

- (void)prepareToReadHeader
{
    assert( _bufferOffset == 0 );
    _buffer = [[NSMutableData alloc] init];
    [_buffer setLength:sizeof(uint64_t)];
    
    _status = P2PIncomingDataStatusReadingHeader;
}

- (void)processHeader
{
    // set file length here
    assert( [_buffer length] == sizeof(uint64_t) );
    uint64_t tmp = * (const uint64_t *) [_buffer bytes];
    _fileSize = (NSUInteger)tmp;
    assert( _fileOffset == 0 );
    assert( _fileSize != 0 );
    _status = P2PIncomingDataStatusReadingData;
}

- (void)prepareNextReadBuffer
{
    if ( _fileOffset < _fileSize )
    {
        // There is more file data to read
        NSUInteger remainingFileSize = _fileSize - _fileOffset;
        NSUInteger nextBufferSize = ( remainingFileSize < P2PNodeConnectionBufferSize ) ? remainingFileSize : P2PNodeConnectionBufferSize;
        [_buffer setLength:nextBufferSize];
        _status = P2PIncomingDataStatusReadingData;
    }
    else
    {
        [self prepareToReadFooter];
    }
}

- (void)processBody
{
    if ( _assembledData == nil )
    {
        _assembledData = [[NSMutableData alloc] initWithCapacity:_fileSize];
    }
    
    // We just received a block of file data.  Update our CRC calculation.
    _crc = (crc_type)crc32(_crc, [_buffer bytes], (uInt) [_buffer length]);
    
    // Append the buffer to our assembled data
    [_assembledData appendBytes:[_buffer bytes] length:[_buffer length]];
    _fileOffset += [_buffer length];
    [_buffer setLength:0];

	// Make sure our file isn't longer than we're expecting
	if ( _fileOffset > _fileSize )
	{
		[self dataDownloadFailedWithError:P2PIncomingDataErrorCodeCurruptFile];
	}

}

- (void)prepareToReadFooter
{
    // It's time for the footer
    [_buffer setLength:sizeof( crc_type )];
    _status = P2PIncomingDataStatusReadingFooter;
}

- (void)processFooter
{
    assert( [_buffer length] == sizeof( crc_type ) );
    uLong crcReceived = * (const crc_type *) [_buffer bytes];
    
    if ( crcReceived == _crc )
    {
        [self dataDownloadDidFinish];
    }
    else
    {
        [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeCurruptFile];
    }
}

- (void)readFromStream
{
    if ( _status == P2PIncomingDataStatusStarting )
    {
        [self prepareToReadHeader];
    }
    
    // Read as much from the stream as we can
    assert( _bufferOffset < [_buffer length] );
    NSInteger actuallyRead = [_connection.inStream read:((uint8_t *)([_buffer mutableBytes]) + _bufferOffset)
                                              maxLength:[_buffer length] - _bufferOffset];
    if ( actuallyRead <= 0 )
    {
        // An error has occoured
        P2PLog( P2PLogLevelError, @"%@ - failed to read from stream: %@", self, [_connection.inStream streamError] );
        [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeStreamError];
    }
    else
    {
        // We have actually read data!
        _bufferOffset += actuallyRead;
        if ( _bufferOffset == [_buffer length] )
        {
            // Buffer is full... process it
            _bufferOffset = 0;
            switch ( _status )
            {
                case P2PIncomingDataStatusReadingHeader:
                {
                    [self processHeader];
                    [self prepareNextReadBuffer];
                    break;
                }
                case P2PIncomingDataStatusReadingData:
                {
                    [self processBody];
                    [self prepareNextReadBuffer];
                    break;
                }
                case P2PIncomingDataStatusReadingFooter:
                {
                    [self processFooter];
                    break;
                }
                default:
                {
                    assert( NO );
                    break;
                }
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
    _assembledData = nil;

    [self returnControlToSender];
    [self.delegate dataFailedToDownload:self];
}

- (void)dataDownloadDidFinish
{
    _status = P2PIncomingDataStatusFinished;
    _downloadedData = _assembledData;
    
    [self returnControlToSender];
    [self.delegate dataDidFinishLoading:self];
    
}

- (void)returnControlToSender
{
    // Return control of the stream to our delegate.
    // For the intents of this P2P demo, we're going to assume that our delegate also
    // implements the NSStreamDelegate protocol...
    assert( self.delegate != nil );
    assert( [self.delegate conformsToProtocol:@protocol(NSStreamDelegate)] );
    assert( [_connection.inStream respondsToSelector:@selector(setDelegate:)] );
    [_connection.inStream setDelegate:(id<NSStreamDelegate>)self.delegate];
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
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self workOutputBufferForStream:connection.outStream buffer:connection.outBuffer];
//    });
    
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
            d.delegate = self;
            
            if ( _activeDataTransfers == nil )
            {
                _activeDataTransfers = [[NSMutableArray alloc] init];
            }
            
            [_activeDataTransfers addObject:d];
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

    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:loader.downloadedData];
    P2PLogDebug(@"%@ - recieved object: %@ from %@", self, obj, loader.connection);
    
    [self handleRecievedObject:obj from:loader.connection];
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
//            dispatch_sync(dispatch_get_main_queue(), ^{
                [self connection:loader.connection failedWithStreamError:NSStreamEventEndEncountered];
//            });
            break;
        }
        case P2PIncomingDataErrorCodeStreamError:
        {
//            dispatch_sync(dispatch_get_main_queue(), ^{
                [self connection:loader.connection failedWithStreamError:NSStreamEventErrorOccurred];
//            });
            
            break;
        }
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

