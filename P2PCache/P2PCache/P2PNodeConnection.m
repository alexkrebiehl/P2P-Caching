//
//  P2PNodeConnection.m
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PNodeConnection.h"
#import "P2PIncomingData.h"
#import <zlib.h>

@implementation P2PNodeConnection

NSData* prepareObjectForTransmission( id<NSCoding> object )
{
    NSData *objectData = [NSKeyedArchiver archivedDataWithRootObject:object];
    file_size_type fileSize = (file_size_type)[objectData length];
    crc_type crc = (crc_type) crc32( 0, [objectData bytes], (uInt)[objectData length] );
    
    // Combine the pieces
    NSMutableData *combinedData = [NSMutableData dataWithCapacity:sizeof( fileSize ) + [objectData length] + sizeof( crc )];
    [combinedData appendBytes:&fileSize length:sizeof( fileSize )];
    [combinedData appendBytes:[objectData bytes] length:[objectData length]];
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
