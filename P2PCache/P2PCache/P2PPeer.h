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

#define P2P_PEER_RESPONSE_INTERVAL 10                       // How often we should ping the peer
#define P2P_PEER_RESPONSE_INTERVAL_TOLERANCE .10            // 10% wiggle room on when our timer runs

static const NSUInteger P2PPeerNoResponse = NSUIntegerMax;  // Value of response time until we recieve an echo from ping




@interface P2PPeer : NSObject

@property (copy, nonatomic, readonly) NSString *ipAddress;  // Peer's IP address
@property (nonatomic, readonly) NSUInteger responseTime;    // ping in milliseconds



/** Create a new object representing a peer
 @param ipAddress The peer's IP Address
 
 @return A new peer object
 */
- (id)initWithIpAddress:(NSString *)ipAddress;



/** Schedules a timer to continiously update the the peer's latency.
 Scheduled automatically when the object is created, so this never really needs
 to be called explicity 
 */
- (void)startUpdatingResponseTime;



/** Stops updating the peer's latency.  Not sure if we will ever need to call this...
 */
- (void)stopUpdatingResponseTime;

@end
