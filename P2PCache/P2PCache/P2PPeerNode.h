//
//  P2PPeerNode.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

/*
 A Peer object contains information about one of our surrounding peers.
 Information such has IP address and response time can be found here.
 */

#import <Foundation/Foundation.h>
#import "P2PNode.h"
#include <arpa/inet.h>

@class P2PPeerNode, P2PPeerFileAvailibilityRequest, P2PFileChunkRequest;

//@protocol P2PPeerProtocol <NSObject>
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


//@interface P2PPeerNode : P2PNode
//
//@property (weak, nonatomic) id<P2PPeerProtocol> delegate;
//
///** The Bonjour object associated with this peer */
//@property (strong, nonatomic, readonly) NSNetService *netService;
//
///** Incidates if this peer is ready to be used.  Attempting to send an object to a peer that is not ready is an error */
//@property (nonatomic, readonly) bool isReady;


/** Create a new object representing a peer
 @param netService The NetService object controling this peer
 
 @return A new peer object 
 */
//- (id)initWithNetService:(NSNetService *)netService;


/** Connects to this peer's I/O streams */
//- (void)preparePeer;


/** Sends an object to this peer
 
 @param transmittableObject An object to send to this peer 
 */
//- (void)sendObjectToPeer:(P2PTransmittableObject *)transmittableObject;

//@end
