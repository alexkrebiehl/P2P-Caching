//
//  P2PPeerLocatorProtocol.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@class P2PPeer;

@protocol P2PPeerLocatorProtocol <NSObject>


/** Callback for when a peer locator service finds a peer 
 @param locator The peer locator service
 @param peer A peer that was found
 */
- (void)peerLocator:(id<P2PPeerLocatorProtocol>)locator didFindPeer:(P2PPeer *)peer;


/** Callback for when a peer locator service looses a peer 
 @param locator The peer locator service
 @param peer A peer that can no longer be contacted
 */
- (void)peerLocator:(id<P2PPeerLocatorProtocol>)locator didLosePeer:(P2PPeer *)peer;

@end
