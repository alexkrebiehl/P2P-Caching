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
#include <arpa/inet.h>

//#define P2P_PEER_RESPONSE_INTERVAL 10               // How often we should ping the peer
//#define P2P_PEER_RESPONSE_INTERVAL_TOLERANCE .10    // 10% wiggle room on when our timer runs

@class P2PPeerNode, P2PFileRequest;

@protocol P2PPeerProtocol <NSObject>

- (void)peerDidBecomeReady:(P2PPeerNode *)peer;
- (void)peerIsNoLongerReady:(P2PPeerNode *)peer;

@end




//static const float P2PPeerNoResponse = MAXFLOAT;    // Value of response time until we recieve an echo from ping




@interface P2PPeerNode : P2PNode

@property (weak, nonatomic) id<P2PPeerProtocol> delegate;

@property (copy, nonatomic, readonly) NSString *ipAddress;  // Peer's IP address
@property (copy, nonatomic, readonly) NSString *domain;     // Peer's resolved domain
@property (nonatomic, readonly) NSUInteger port;            // Port number
//@property (nonatomic, readonly) float responseTime;         // ping in milliseconds

@property (strong, nonatomic, readonly) NSNetService *netService;
@property (nonatomic, readonly) bool peerIsReady;

/** Create a new object representing a peer
 @param netService The NetService object controling this peer
 
 @return A new peer object 
 */
- (id)initWithNetService:(NSNetService *)netService;

/** Resolves the peer's IP address and connects to their I/O streams */
- (void)preparePeer;


// File Handling
- (void)getFileAvailabilityForRequest:(P2PFileRequest *)request;

@end
