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

@protocol P2PPeerProtocol <NSObject>

- (void)peerDidBecomeReady:(P2PPeerNode *)peer;
- (void)peerIsNoLongerReady:(P2PPeerNode *)peer;

@end


@interface P2PPeerNode : P2PNode

@property (weak, nonatomic) id<P2PPeerProtocol> delegate;

@property (strong, nonatomic, readonly) NSNetService *netService;
@property (nonatomic, readonly) bool isReady;

/** Create a new object representing a peer
 @param netService The NetService object controling this peer
 
 @return A new peer object 
 */
- (id)initWithNetService:(NSNetService *)netService;

/** Resolves the peer's IP address and connects to their I/O streams */
- (void)preparePeer;

- (void)sendObjectToPeer:(P2PTransmittableObject *)object;

// File Handling
//- (void)requestFileAvailability:(P2PPeerFileAvailibilityRequest *)request;
//
//- (void)requestFileChunk:(P2PFileChunkRequest *)request;

@end
