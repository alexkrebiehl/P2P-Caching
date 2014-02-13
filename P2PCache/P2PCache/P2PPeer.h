//
//  P2PPeer.h
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

#define P2P_PEER_RESPONSE_INTERVAL 10               // How often we should ping the peer
#define P2P_PEER_RESPONSE_INTERVAL_TOLERANCE .10    // 10% wiggle room on when our timer runs

@class P2PPeer, P2PFileRequest;

@protocol P2PPeerProtocol <NSObject>

- (void)peerDidBecomeReady:(P2PPeer *)peer;
- (void)peerIsNoLongerReady:(P2PPeer *)peer;

@end




static const float P2PPeerNoResponse = MAXFLOAT;    // Value of response time until we recieve an echo from ping




@interface P2PPeer : P2PNode

@property (weak, nonatomic) id<P2PPeerProtocol> delegate;

@property (copy, nonatomic, readonly) NSString *ipAddress;  // Peer's IP address
@property (copy, nonatomic, readonly) NSString *domain;     // Peer's resolved domain
@property (nonatomic, readonly) NSUInteger port;            // Port number
@property (nonatomic, readonly) float responseTime;         // ping in milliseconds

@property (strong, nonatomic, readonly) NSNetService *netService;
@property (nonatomic, readonly) bool peerIsReady;


- (id)initWithNetService:(NSNetService *)netService;
- (void)preparePeer;


// File Handling
- (void)getFileAvailabilityForRequest:(P2PFileRequest *)request;

/** Create a new object representing a peer
 @param ipAddress The peer's IP Address
 @param port The peer's port number
 @param domain The peer's resolved domain name
 
 @return A new peer object
 */
//- (id)initWithIpAddress:(NSString *)ipAddress port:(NSUInteger)port domain:(NSString *)domain;



/** Schedules a timer to continiously update the the peer's latency.
 Scheduled automatically when the object is created, so this never really needs
 to be called explicity 
 */
//- (void)startUpdatingResponseTime;



/** Stops updating the peer's latency.  Not sure if we will ever need to call this...
 */
//- (void)stopUpdatingResponseTime;

@end
