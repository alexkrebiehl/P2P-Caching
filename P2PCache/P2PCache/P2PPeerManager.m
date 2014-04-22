//
//  P2PPeerManager.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PPeerManager.h"
#import "P2PServerNode.h"

NSString *P2PPeerManagerPeerListUpdatedNotification = @"P2PPeerManagerPeerListUpdatedNotification";

@interface P2PPeerManager() < NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@end

@implementation P2PPeerManager
{
    P2PServerNode   *_serverInstance;       // Us broadcasting to others that we offer a service
    NSMutableSet *_activePeers;             // Peers we are connected to and ready to interact with
    NSNetServiceBrowser *_serviceBrowser;   // Searches for peers
    NSMapTable *_netServiceToNodeMapping;
}
@synthesize activePeers = _activePeers;

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
	_serverInstance = [[P2PServerNode alloc] initWithInputStream:nil outputStream:nil displayableName:@"Server Node"];
    [_serverInstance beginBroadcasting];
    
    // Find some peeps
    _activePeers = [[NSMutableSet alloc] init];
    _netServiceToNodeMapping = [NSMapTable strongToStrongObjectsMapTable];
    [self beginSearching];
}

- (void)cleanup
{
    [_serviceBrowser stop];
    [_serverInstance cleanup];
    
    NSEnumerator *enumerator = [_netServiceToNodeMapping objectEnumerator];
    id obj;
    while ( obj = [enumerator nextObject] )
    {
        [obj cleanup];
    }
}

- (void)beginSearching
{
    if ( _serviceBrowser == nil )
    {
        _serviceBrowser = [[NSNetServiceBrowser alloc] init];
        [_serviceBrowser setDelegate:self];
        [_serviceBrowser searchForServicesOfType:P2P_BONJOUR_SERVICE_TYPE
                                        inDomain:P2P_BONJOUR_SERVICE_DOMAIN];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didNotSearch:(NSDictionary *)errorDict
{
    P2PLog( P2PLogLevelError, @"******** ERROR SEARCHING FOR PEERS ********" );
    P2PLog( P2PLogLevelError, @"Error code: %@", [errorDict objectForKey:NSNetServicesErrorCode] );
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    // Found a peer
    if ( [aNetService.type isEqualToString:P2P_BONJOUR_SERVICE_TYPE] )
    {
        // open streams
        NSInputStream		*inStream;
        NSOutputStream		*outStream;
        bool successfulConnection = [aNetService getInputStream:&inStream outputStream:&outStream];
        if ( successfulConnection )
        {
            P2PLog( P2PLogLevelNormal, @"%@ - Successfully connected to server's I/O streams", self);
            
            P2PNode *node = [[P2PNode alloc] initWithInputStream:inStream outputStream:outStream displayableName:aNetService.name];
            [_netServiceToNodeMapping setObject:node forKey:aNetService];
            [_activePeers addObject:node];
            [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
        }
        else
        {
            P2PLog( P2PLogLevelWarning, @"%@ - Failed to connect to server's I/O streams", self );
        }
    }
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    if ( [aNetService.type isEqualToString:P2P_BONJOUR_SERVICE_TYPE] )
    {
        P2PNode *node = [_netServiceToNodeMapping objectForKey:aNetService];
        
        [_netServiceToNodeMapping removeObjectForKey:aNetService];
        [_activePeers removeObject:node];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>", [self class]];
}

@end
