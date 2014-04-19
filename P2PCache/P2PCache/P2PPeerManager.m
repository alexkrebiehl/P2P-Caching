//
//  P2PPeerManager.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerManager.h"
#import "P2PServerNode.h"
#import "P2PPeerNode.h"
#import "P2PLocatorDelegate.h"

@interface P2PPeerManager() <P2PPeerProtocol, NSNetServiceBrowserDelegate>
@end


@implementation P2PPeerManager
{
    P2PServerNode   *_peerServer;           // Us broadcasting to others that we offer a service
    
    NSMutableSet *_activePeers;           // Peers we are connected to and ready to interact with
//    NSMutableSet *_inactivePeers;         // Peers that are no longer connected (for debugging)
    
    NSNetServiceBrowser *_serviceBrowser;   // Searches for peers
}
@synthesize activePeers = _activePeers;
//@synthesize inactivePeers = _inactivePeers;





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
    _peerServer = [[P2PServerNode alloc] init];
    [_peerServer beginBroadcasting];
    
    // Find some peeps
//    _allPeers = [[NSMutableSet alloc] init];
    _activePeers = [[NSMutableSet alloc] init];
    [self beginSearching];
}

- (void)cleanup
{
    [_serviceBrowser stop];
    [_peerServer cleanup];
    for ( P2PNode *node in self.activePeers )
    {
        [node cleanup];
    }
}

- (void)beginSearching
{
    if ( _serviceBrowser == nil )
    {
        _serviceBrowser = [[NSNetServiceBrowser alloc] init];
        [_serviceBrowser setDelegate:self];
        [_serviceBrowser searchForServicesOfType:P2P_BONJOUR_SERVICE_TYPE inDomain:P2P_BONJOUR_SERVICE_DOMAIN];
    }
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    P2PLog( P2PLogLevelNormal, @"---- Beginning search for peers ----" );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    P2PLog( P2PLogLevelError, @"******** ERROR SEARCHING FOR PEERS ********" );
    P2PLog( P2PLogLevelError, @"Error code: %@", [errorDict objectForKey:NSNetServicesErrorCode] );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if ( [aNetService.type isEqualToString:P2P_BONJOUR_SERVICE_TYPE] )
    {
        P2PPeerNode *aPeer = [[P2PPeerNode alloc] initWithNetService:aNetService];
        [_activePeers addObject:aPeer];
        aPeer.delegate = self;
        [aPeer preparePeer];
    }
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if ( [aNetService.type isEqualToString:P2P_BONJOUR_SERVICE_TYPE] )
    {
        // Find a good way to do this
        P2PLog( P2PLogLevelNormal, @"******** DID LOSE PEER: %@ NEED TO HANDLE **********", aNetService.name );
        for ( P2PPeerNode *peer in _activePeers )
        {
            if ( peer.netService == aNetService )
            {
                [self peerIsNoLongerReady:peer];
            }
        }
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    P2PLog( P2PLogLevelNormal, @"---- Stopping peer search ----");
}




#pragma mark - P2PPeer Delegate Methods
- (void)peerDidBecomeReady:(P2PPeerNode *)peer
{
    P2PLogDebug( @"%@ - peer did become ready", peer );
    [_activePeers addObject:peer];
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
}

- (void)peerIsNoLongerReady:(P2PPeerNode *)peer
{
    P2PLogDebug( @"%@ - peer is no longer ready", peer );
    [_activePeers removeObject:peer];
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
}

@end
