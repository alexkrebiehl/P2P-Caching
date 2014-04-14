//
//  P2PNodeConnection.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Serializes an object to be sent to another peer.  Adds header and footer information to the binary data */
NSData* prepareObjectForTransmission( id<NSCoding> object );

enum
{
    /** The default buffer size */
    P2PNodeConnectionBufferSize = 32 * 1024, // 32kb buffer
};


/** Represents a connection between two nodes.  Contains the connection ID, both I/O streams, and buffers */
@interface P2PNodeConnection : NSObject

/** The unique Id of this connection */
@property (nonatomic, readonly) NSUInteger connectionId;

/** Input stream of this connection */
@property (weak, nonatomic) NSInputStream *inStream;

/** Input buffer of this connection */
@property (strong, nonatomic) NSMutableData *inBuffer;

/** Output stream of this connection */
@property (weak, nonatomic) NSOutputStream *outStream;

/** Output buffer of this connection */
@property (strong, nonatomic) NSMutableData *outBuffer;

@end
