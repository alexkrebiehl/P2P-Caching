//
//  P2PPeerManager.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerManager.h"
#import "P2PPeerServer.h"
#import "P2PPeerLocator.h"
#import "P2PPeerLocatorProtocol.h"

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



@interface P2PPeerManager()<P2PPeerLocatorProtocol>
@end


@implementation P2PPeerManager
{
    P2PPeerServer   *_peerServer;           // Us broadcasting to others that we offer a service
    P2PPeerLocator  *_peerLocatorService;   // Us seeking out other servers
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
    _peerServer = [[P2PPeerServer alloc] init];
    [_peerServer beginBroadcasting];
    
    
    _peerLocatorService = [[P2PPeerLocator alloc] init];
    [_peerLocatorService setDelegate:self];
    [_peerLocatorService beginSearching];
    
}

- (NSArray *)findBestPeers:(NSUInteger)numberOfPeersToFind
{
    // Go through our peer data structure
    return nil;
}

#pragma mark - P2PPeerLocator delegate methods
- (void)peerLocator:(id<P2PPeerLocatorProtocol>)locator didFindPeer:(P2PPeer *)peer
{
    // probably add peer to an array here, maybe sort them by response time
    // shit like that
}

- (void)peerLocator:(id<P2PPeerLocatorProtocol>)locator didLosePeer:(P2PPeer *)peer
{
    
}

@end
