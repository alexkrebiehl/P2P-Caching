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

@interface P2PNode : NSObject <P2PNodeConnectionDelegate>

/** Unique identifier for this node */
@property (strong, readonly, nonatomic) NSNumber *nodeID;

/** Objection representing a connection to this node */
@property (strong, nonatomic, readonly) P2PNodeConnection *connection;

/** Human readable name of this node */
@property (copy, nonatomic, readonly) NSString *displayableName;


/** Creates a new node object with an input and output stream.
 
 @param inStream The input stream connected to this node
 @param outStream The output stream connected to this node
 @param name The human readable name to be given to this node
 @return A new node object representing a peer on the P2P network
 */
- (id)initWithInputStream:(NSInputStream *)inStream outputStream:(NSOutputStream *)outStream displayableName:(NSString *)name;


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


