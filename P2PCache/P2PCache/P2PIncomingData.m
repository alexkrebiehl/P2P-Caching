//
//  P2PIncomingData.m
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PIncomingData.h"
#import "P2PNodeConnection.h"
#import <zlib.h>


@implementation P2PIncomingData
{
    NSMutableData *_buffer;
    NSUInteger _bufferOffset;
    NSUInteger _fileOffset;
    
    crc_type _crc;
    NSMutableData *_assembledData;
    
    file_size_type _fileSize;
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

- (void)startDownloadingData
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
    [_buffer setLength:sizeof( file_size_type )];
    
    _status = P2PIncomingDataStatusReadingHeader;
}

- (void)processHeader
{
    // set file length here
    assert( [_buffer length] == sizeof( file_size_type ) );
    file_size_type tmp = * (const file_size_type *) [_buffer bytes];
    _fileSize = tmp;
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
        P2PLog( P2PLogLevelError, @"%@ - failed to read from stream: %@", self, _connection.inStream );
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
