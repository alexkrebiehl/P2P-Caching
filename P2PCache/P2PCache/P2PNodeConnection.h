//
//  P2PNodeConnection.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "P2PNodeConnectionDelegate.h"

/** Serializes an object to be sent to another peer.  Adds header and footer information to the binary data 
 
 Packet format:
    32-bit file size (file_size_type)
    archived object
    32-bit checksum (crc_type)
 */
NSData * prepareObjectForTransmission( id<NSCoding> object );

enum
{
    /** The default buffer size */
    P2PNodeConnectionBufferSize = 32 * 1024, // 32kb buffer
};

typedef uint32_t file_size_type;
typedef uint32_t crc_type;

static const file_size_type P2PIncomingDataFileSizeUnknown = UINT32_MAX;



/** Represents a connection between two nodes.  Contains the connection ID, both I/O streams, and buffers */
@interface P2PNodeConnection : NSObject

/** The unique Id of this connection */
@property (nonatomic, readonly) NSUInteger connectionId;

/** A delegate to recieve callbacks for status updates of this transmission */
@property (weak, nonatomic) id<P2PNodeConnectionDelegate> delegate;


/** Create a new connection from an input and output stream
 
 @param inStream An input stream object.  May not be @c nil
 @param outStream An output stream object.  May not be @c nil
 @return A new object representing a connection 
 */
- (id)initWithInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;


/** Buffer data to be sent to the connection.
 
 @param data Data to be sent to the node
 */
- (void)sendDataToConnection:(NSData *)data;


/** Closes the input and output streams.  The connection object should be discarded after calling this
 */
- (void)dropConnection;


/** Opens the input and out streams and prepares for communication.  The @c delegate should be set before calling this method
 */
- (void)openConnection;



@end
