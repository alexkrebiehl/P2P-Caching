//
//  P2PPeerManager.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerManager.h"
#import "P2PBonjourServer.h"
#import "P2PBonjourClient.h"

/**
 
 My thoughts for this are:
 
    --- Startup ---
    1.  We send a broadcast announcement that we are alive.
    2.  Any peers currently running will recieve the broadcast and respond with their information
    3.  We will track all of this information and use some kind of hueristic to determine the best peers

    --- Running ---
    1.  We will perodically 'check' on our peer list to make sure everyone is still active.
    2.  Perodically re-priortize the peer list depending on our hueristic
 
    --- Shutdown ---
    1.  Announce our departure to our peer list so they don't continue trying to use us
 
 
 */






@implementation P2PPeerManager
{
    P2PBonjourServer *_bonjourServer;   // Us broadcasting to others that we offer a service
    P2PBonjourClient *_bonjourClient;   // Us seeking out other servers
}

static P2PPeerManager *sharedInstance = nil;

#pragma mark - Initialization Methods
+ (P2PPeerManager *)sharedManager
{
    if (sharedInstance == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^ { sharedInstance = [[[self class] alloc] init]; });
    }
    return sharedInstance;
}

- (void)start
{
    _bonjourServer = [[P2PBonjourServer alloc] init];
    _bonjourClient = [[P2PBonjourClient alloc] init];
    
    // Tell other peers we are here!
    [self announce];
    
}

- (void)announce
{
    // Tell everyone else we exist
}

- (void)recieveAcknowledgementFromPeer//:(P2PPeerResponse *response)
{
    // A peer responded to our announcement
    
}

@end
