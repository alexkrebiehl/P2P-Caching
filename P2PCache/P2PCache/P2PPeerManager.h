//
//  P2PPeerManager.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Default number of peers to return for -findBestPeers: */
static const NSUInteger P2PPeerManagerDefaultNumberOfPeers =    10;

/** Notification for when the peer list is updated */
static NSString *P2PPeerManagerPeerListUpdatedNotification =    @"P2PPeerManagerPeerListUpdatedNotification";




@interface P2PPeerManager : NSObject

/** A shared manager to handle the tracking of compatable peers */
+ (P2PPeerManager *)sharedManager;



/** Perform setup when the system starts */
- (void)start;




/** Returns a sorted array of the best N peers.  
 
 @param numberOfPeersToFind How many peers to return.  May use 'P2PPeerManagerDefaultNumberOfPeers'
 
 @return A sorted array of the best peers available
 */
- (NSArray *)findBestPeers:(NSUInteger)numberOfPeersToFind;

@end
