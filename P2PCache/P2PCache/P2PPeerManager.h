//
//  P2PPeerManager.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Notification for when the peer list is updated */
static NSString *P2PPeerManagerPeerListUpdatedNotification =    @"P2PPeerManagerPeerListUpdatedNotification";

@interface P2PPeerManager : NSObject

@property (strong, readonly, nonatomic) NSArray *activePeers;
@property (strong, readonly, nonatomic) NSArray *allPeers;

/** A shared manager to handle the tracking of compatable peers */
+ (P2PPeerManager *)sharedManager;

/** Perform setup when the system starts */
- (void)start;

@end
