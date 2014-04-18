//
//  P2PNodeConnection.m
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNodeConnection.h"
#import <zlib.h>

@interface P2PNodeConnection () <NSStreamDelegate>

@property (atomic) bool outBufferIsBeingWorked;
@property (atomic) NSUInteger positionInCurrentBufferItem;
@property (atomic) NSMutableArray *outputBufferQueue;
@property (nonatomic, readwrite) NSUInteger connectionId;

/** Input stream of this connection */
@property (strong, nonatomic, readwrite) NSInputStream *inStream;

/** Output stream of this connection */
@property (strong, nonatomic, readwrite) NSOutputStream *outStream;

/** Input buffer of this connection */
@property (strong, nonatomic) NSMutableData *inBuffer;

/** The current status of this loader object */
@property (nonatomic) P2PIncomingDataStatus status;

@end

@implementation P2PNodeConnection
{
    NSUInteger _bufferOffset;
    NSUInteger _fileOffset;
    
    crc_type _incomingCRC;
    NSMutableData *_assembledData;
    
    file_size_type _fileSize;
}

NSData* prepareObjectForTransmission( id<NSCoding> object )
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    file_size_type fileSize = (file_size_type)[objectData length];
    crc_type crc = (crc_type) crc32( 0, [objectData bytes], (uInt)[objectData length] );
    
    // Combine the pieces
    NSMutableData *combinedData = [NSMutableData dataWithCapacity:sizeof( fileSize ) + [objectData length] + sizeof( crc )];
//    [NSMutableData alloc] initwith    
    [combinedData appendBytes:&fileSize length:sizeof( fileSize )];
    [combinedData appendData:objectData];
//    [combinedData appendBytes:[objectData bytes] length:[objectData length]];
    [combinedData appendBytes:&crc length:sizeof( crc )];
    
    
    return combinedData;
}


NSUInteger getNextConnectionId()
{
    static NSUInteger nextId = 1;
    return nextId++;
}


- (id)init
{
    return [self initWithInputStream:nil outputStream:nil];
}

- (id)initWithInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream
{
    assert( inStream != nil );
    assert( outStream != nil );
    
    if ( self = [super init] )
    {
        self.connectionId = getNextConnectionId();
        
        self.inStream = inStream;
        self.outStream = outStream;
        
        self.status = P2PIncomingDataStatusNotStarted;
        _fileSize = P2PIncomingDataFileSizeUnknown;
        _bufferOffset = 0;
    }
    return self;
}

- (void)openConnection
{
    assert( self.inStream != nil );
    assert( self.outStream != nil );
    
    self.inStream.delegate = self;
    [self.inStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inStream open];
    
    self.outStream.delegate = self;
    [self.outStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outStream open];
}

- (void)dropConnection
{
    self.inStream.delegate = nil;
    [self.inStream close];
    self.inStream = nil;
    
    self.outStream.delegate = nil;
    [self.outStream close];
    self.outStream = nil;
    
    [self cleanupInputBuffers];
    self.outputBufferQueue = nil;
    
    [self.delegate nodeConnectionDidEnd:self];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ - ID: %lu>", [self class], (unsigned long)_connectionId];
}

- (void)sendDataToConnection:(NSData *)data;
{
    if ( self.outputBufferQueue == nil )
    {
        self.outputBufferQueue = [[NSMutableArray alloc] init];
    }
    
    [self.outputBufferQueue addObject:data];
    [self workOutputBuffer];
}

- (void)workOutputBuffer
{
    assert( self.outStream != nil );
    
    if ( ! self.outBufferIsBeingWorked )
    {
        self.outBufferIsBeingWorked = YES;
        NSData *currentItem = [self.outputBufferQueue firstObject];
        
        while ( currentItem.length > self.positionInCurrentBufferItem && [self.outStream hasSpaceAvailable] )
        {
            // sending NSData over to server
            NSInteger writeResult = [self.outStream write:[currentItem bytes] + self.positionInCurrentBufferItem
                                                maxLength:[currentItem length] - self.positionInCurrentBufferItem];
            
            if ( writeResult == -1 )
            {
                P2PLog( P2PLogLevelError, @"Failed to write to output stream: %@", self.outStream );
            }
            else
            {
                self.positionInCurrentBufferItem += writeResult;
            }
            
            // Check to see if we're done with the current buffer item
            // If so, move on to the next
            if ( self.positionInCurrentBufferItem == [currentItem length] )
            {
                [self.outputBufferQueue removeObject:currentItem];
                self.positionInCurrentBufferItem = 0;
                
                currentItem = [self.outputBufferQueue firstObject];
            }
            
        }

        self.outBufferIsBeingWorked = NO;
    }
}

#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
            [self readFromInStream];
            break;
        case NSStreamEventEndEncountered:
            [self dropConnection];
            break;
        case NSStreamEventErrorOccurred:
            [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeStreamError];
            break;
        case NSStreamEventHasSpaceAvailable:
            [self workOutputBuffer];
            break;
        case NSStreamEventOpenCompleted:
        case NSStreamEventNone:
        default:
            break;
    }
}

- (void)prepareToReadHeader
{
    _fileSize = P2PIncomingDataFileSizeUnknown;
    _bufferOffset = 0;
    _fileOffset = 0;
    _incomingCRC = 0;
    
    self.inBuffer = [[NSMutableData alloc] init];
    [self.inBuffer setLength:sizeof( file_size_type )];
    
    self.status = P2PIncomingDataStatusReadingHeader;
}

- (void)processHeader
{
    // set file length here
    assert( [self.inBuffer length] == sizeof( file_size_type ) );
    file_size_type tmp = * (const file_size_type *) [self.inBuffer bytes];
    _fileSize = tmp;
    assert( _fileOffset == 0 );
    assert( _fileSize != 0 );
    self.status = P2PIncomingDataStatusReadingData;
}

- (void)prepareNextReadBuffer
{
    if ( _fileOffset < _fileSize )
    {
        // There is more file data to read
        NSUInteger remainingFileSize = _fileSize - _fileOffset;
        NSUInteger nextBufferSize = ( remainingFileSize < P2PNodeConnectionBufferSize ) ? remainingFileSize : P2PNodeConnectionBufferSize;
        [self.inBuffer setLength:nextBufferSize];
        self.status = P2PIncomingDataStatusReadingData;
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
    _incomingCRC = (crc_type)crc32(_incomingCRC, [self.inBuffer bytes], (uInt)[self.inBuffer length]);
    
    // Append the buffer to our assembled data
    [_assembledData appendBytes:[self.inBuffer bytes] length:[self.inBuffer length]];
    _fileOffset += [self.inBuffer length];
    [self.inBuffer setLength:0];
    
	// Make sure our file isn't longer than we're expecting
	if ( _fileOffset > _fileSize )
	{
		[self dataDownloadFailedWithError:P2PIncomingDataErrorCodeCurruptFile];
	}
    
}

- (void)prepareToReadFooter
{
    // It's time for the footer
    [self.inBuffer setLength:sizeof( crc_type )];
    self.status = P2PIncomingDataStatusReadingFooter;
}

- (void)processFooter
{
    assert( [self.inBuffer length] == sizeof( crc_type ) );
    uLong crcReceived = * (const crc_type *) [self.inBuffer bytes];
    
    if ( crcReceived == _incomingCRC )
    {
        [self dataDownloadDidFinish];
    }
    else
    {
        [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeCurruptFile];
    }
}

- (void)readFromInStream
{
    if ( self.status == P2PIncomingDataStatusNotStarted )
    {
        [self prepareToReadHeader];
    }
    
    // Read as much from the stream as we can
    assert( _bufferOffset < [self.inBuffer length] );
    NSInteger actuallyRead = [self.inStream read:((uint8_t *)([self.inBuffer mutableBytes]) + _bufferOffset)
                                       maxLength:[self.inBuffer length] - _bufferOffset];
    if ( actuallyRead <= 0 )
    {
        // An error has occoured
        P2PLog( P2PLogLevelError, @"%@ - failed to read from stream: %@", self, self.inStream.streamError );
        [self dataDownloadFailedWithError:P2PIncomingDataErrorCodeStreamError];
    }
    else
    {
        // We have actually read data!
        _bufferOffset += actuallyRead;
        if ( _bufferOffset == [self.inBuffer length] )
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
    self.status = P2PIncomingDataStatusNotStarted;
    [self cleanupInputBuffers];
    
    [self.delegate nodeConnection:self failedToDownloadWithError:errorCode];
}

- (void)dataDownloadDidFinish
{
    self.status = P2PIncomingDataStatusNotStarted;
    id obj = [NSKeyedUnarchiver unarchiveObjectWithData:_assembledData];
    [self cleanupInputBuffers];
    
    [self.delegate nodeConnection:self didRecieveObject:obj];
}

- (void)cleanupInputBuffers
{
    self.inBuffer = nil;
    _assembledData = nil;
}


@end