//
//  P2PNode.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/12/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "P2PNodeConnectionDelegate.h"

@class P2PTransmittableObject, P2PNodeConnection;


//@protocol P2PNodeDelegate <NSObject>
//
///** When a peer is ready to be used, this delegate method will be called
// 
// @param peer A peer object that is ready to be used
// */
//- (void)peerDidBecomeReady:(P2PPeerNode *)peer;
//
///** When a peer is no longer ready to be used, this delegate method will be called.  Attempting to transmit an
// object to this peer after this is called is an error
// 
// @param peer A peer object that is no longer ready
// */
//- (void)peerIsNoLongerReady:(P2PPeerNode *)peer;
//
//@end




@interface P2PNode : NSObject <P2PNodeConnectionDelegate>

/** Unique identifier for this node */
@property (strong, readonly, nonatomic) NSNumber *nodeID;

/** Objection representing a connectio n to this node */
@property (strong, nonatomic, readonly) P2PNodeConnection *connection;

@property (copy, nonatomic, readonly) NSString *displayableName;

- (id)initWithInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream displayableName:(NSString *)name;


/** Call this method when recieving input/output streams from a server.
 
 @param inStream An input stream supplied by a NSNetService instance
 @param outStream An output stream supplied by a NSNetService instance
 */
//- (void)takeOverInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream;


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


