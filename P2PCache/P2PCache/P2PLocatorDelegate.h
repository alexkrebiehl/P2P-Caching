//
//  P2PLocatorDelegate.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/1/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
    This protocol allows us to easily change how we look for peers.
    All we would have to do is implement a class using this protocol as its delegate,
    and all of our other code should work the same.
 
    The only thing we would have to do is change which service gets instantiated in
    the P2PPeerManager class.  All communication to classes outside of the peer locator
    should be done through this protocol.
 
 */


@class P2PPeerLocator, P2PPeerNode;

@protocol P2PPeerLocatorDelegate <NSObject>


/** Callback for when a peer locator service finds a peer
 @param locator The peer locator service
 @param peer A peer that was found
 */
- (void)peerLocator:(P2PPeerLocator *)locator didFindPeer:(P2PPeerNode *)peer;


/** Callback for when a peer locator service looses a peer
 @param locator The peer locator service
 @param peer A peer that can no longer be contacted
 */
- (void)peerLocator:(P2PPeerLocator *)locator didLosePeer:(P2PPeerNode *)peer;

@end