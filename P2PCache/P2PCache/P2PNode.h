//
//  P2PNode.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PNodeConnection, P2PTransmittableObject;

@interface P2PNode : NSObject <NSStreamDelegate>
@property (strong, readonly, nonatomic) NSNumber *nodeID;


/** This method will be called when the node recieves an object.  Subclasses MUST override this method
 and handle any incoming objects.  Subclasses don't need to call this method directly.
 
 @param object The recieved object
 @param sender The service which this object came from
 */
- (void)handleReceivedObject:(P2PTransmittableObject *)object from:(P2PNodeConnection *)sender;


/** When an object is unable to be sent across the network connection 
 
 (Not implemented yet)
 */
- (void)objectDidFailToSend:(id)object;

- (void)connection:(P2PNodeConnection *)node failedWithStreamError:(NSStreamEvent)errorEvent;

@end

@interface P2PNode ( MethodsNotToBeSubclassed )

/** Call this method when recieving input/output streams from a server.  
 
 @param inStream An input stream supplied by a NSNetService instance
 @param outStream An output stream supplied by a NSNetService instance
 */
- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;

/** Transmits an object to a peer's cache server.
 
 @param transmittableObject The object to send
 */
- (void)transmitObject:(P2PTransmittableObject *)transmittableObject;


/** Transmits an object to a peer that is connected through a NSNetService object.
 This method will be used by a server instance of P2PNode to specify which peer to send the object to.
 
 @param transmittableObject An object to send
 @param connection The P2PNodeConnection instance object connected to a peer.
 */
- (void)transmitObject:(P2PTransmittableObject *)transmittableObject toNodeConnection:(P2PNodeConnection *)connection;

@end


