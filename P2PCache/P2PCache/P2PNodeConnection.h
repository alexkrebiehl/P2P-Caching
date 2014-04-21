//
//  P2PNodeConnection.h
//  P2PCache
//
//  Created by Alex Krebiehl on 4/7/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "P2PNodeConnectionDelegate.h"

enum
{
    /** The default buffer size */
    P2PNodeConnectionBufferSize = 32 * 1024, // 32kb buffer
};



/** Represents a connection between two nodes.  Contains the connection ID, both I/O streams, and buffers */
@interface P2PNodeConnection : NSObject

/** The unique Id of this connection */
@property (nonatomic, readonly) NSUInteger connectionId;

/** A delegate to recieve callbacks for status updates of this transmission */
@property (weak, nonatomic) id<P2PNodeConnectionDelegate> delegate;


/** Create a new connection from an input and output stream
 
 @param inStream An input stream object.  Must not be @c nil
 @param outStream An output stream object.  Must not be @c nil
 @return A new object representing a connection 
 */
- (id)initWithInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;


/** Buffer data to be sent to the connection.
 
 @param data Data to be sent to the node
 */
- (void)sendData:(NSData *)data;


/** Closes the input and output streams.  The connection object should be discarded after calling this
 */
- (void)dropConnection;


/** Opens the input and out streams and prepares for communication.  The @c delegate should be set before calling this method
 */
- (void)openConnection;



@end
