//
//  P2PNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNode.h"

@implementation P2PNode

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

#import "P2PNetworkTool.h"

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
    NSMutableData *compositeData = [[NSMutableData alloc] initWithCapacity:P2PNetworkTransmissionHeaderSize + dataToTransmit.length];
    
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
NSData* prepareObjectForTransmission( id<NSCopying> object )
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
        
        
        NSLog(@"byte: %c", oneByte);
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

