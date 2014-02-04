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
#import "P2PPeer.h"
#import "P2PLocatorDelegate.h"

/**
 
 My thoughts for this are:
 
    --- Startup ---
    1.  We send a broadcast announcement that we are alive.
    2.  Any peers currently running will recieve the broadcast and respond with their information
    3.  We will track all of this information and use some kind of hueristic to determine the best peers
        --- I think steps 1 & 2 are handled for us by Bonjour (P2PLocator class) ---

    --- Running ---
    1.  We will perodically 'check' on our peer list to make sure everyone is still active.
        --- I have the P2PPeer class periodically ping right now ---
    2.  Perodically re-priortize the peer list depending on our hueristic
 
    --- Shutdown ---
    1.  Announce our departure to our peer list so they don't continue trying to use us
 
 
 */

static const NSTimeInterval peerResortInterval = 10;    // Resort the peer list every 10 seconds
                                                        // I already feel dirty for doing it this way
                                                        // I'll think of a better way later

@interface P2PPeerManager()<P2PPeerLocatorDelegate>
@end


@implementation P2PPeerManager
{
    P2PPeerServer   *_peerServer;           // Us broadcasting to others that we offer a service
    P2PPeerLocator  *_peerLocatorService;   // Us seeking out other servers
    NSMutableArray  *_foundPeers;           // List of peers (we'll probabibly do something better later)
    NSDate          *_lastPeerSort;         // How long ago we last sorted the peer list.
}





#pragma mark - Initialization Methods
static P2PPeerManager *sharedInstance = nil;
+ (P2PPeerManager *)sharedManager
{    
    if (sharedInstance == nil)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ sharedInstance = [[[self class] alloc] init]; });
    }
    return sharedInstance;
}






- (void)start
{
    // Make ourselves known to others
    _peerServer = [[P2PPeerServer alloc] init];
    [_peerServer beginBroadcasting];
    
    // Find some peeps
    _peerLocatorService = [[P2PPeerLocator alloc] init];
    [_peerLocatorService setDelegate:self];
    [_peerLocatorService beginSearching];
}


- (NSArray *)findBestPeers:(NSUInteger)numberOfPeersToFind
{
    /*
     
     Yeah, this is real bad.
     
     I think what we can do here is keep our entire peer list here,
     than occasionally go through it and pick out 'prefered' peers,
     such as ones than have a ping of 1-10ms or something.
     
     This way we're not constantly going through the entire list constantly
     
     */
    
    
    
    // Go through our peer data structure
    if ( _lastPeerSort == nil || ABS([_lastPeerSort timeIntervalSinceNow]) < peerResortInterval )
    {
        _lastPeerSort = [[NSDate alloc] init];
        [_foundPeers sortUsingComparator:^NSComparisonResult(P2PPeer *obj1, P2PPeer *obj2)
        {
            if ( obj1.responseTime < obj2.responseTime )
            {
                return NSOrderedAscending;
            }
            else if (obj1.responseTime > obj2.responseTime )
            {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
    }
    
    return _foundPeers;
}





#pragma mark - P2PPeerLocator delegate methods
- (void)peerLocator:(P2PPeerLocator *)locator didFindPeer:(P2PPeer *)peer
{
    // probably add peer to an array here, maybe sort them by response time
    // shit like that
    LogSelector();
    NSLog(@"Peer: %@", peer);
    
    if (_foundPeers == nil)
    {
        _foundPeers = [[NSMutableArray alloc] init];
    }
    [_foundPeers addObject:peer];
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
}

- (void)peerLocator:(P2PPeerLocator *)locator didLosePeer:(P2PPeer *)peer
{
    [_foundPeers removeObject:peer];
}

@end
