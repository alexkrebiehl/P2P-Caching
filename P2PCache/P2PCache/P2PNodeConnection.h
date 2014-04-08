//
//  P2PNodeConnection.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

NSData* prepareObjectForTransmission( id<NSCoding> object );

enum
{
    P2PNodeConnectionBufferSize = 32 * 1024, // 32kb buffer
};


/** Represents a connection between two nodes.  Contains the connection ID, both I/O streams, and buffers */
@interface P2PNodeConnection : NSObject

@property (nonatomic, readonly) NSUInteger connectionId;

@property (weak, nonatomic) NSInputStream *inStream;
@property (strong, nonatomic) NSMutableData *inBuffer;

@property (weak, nonatomic) NSOutputStream *outStream;
@property (strong, nonatomic) NSMutableData *outBuffer;

@end
