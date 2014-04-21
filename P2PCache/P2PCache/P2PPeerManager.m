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

@interface P2PPeerManager() < NSNetServiceBrowserDelegate, NSNetServiceDelegate> // P2PPeerProtocol,
@end


@implementation P2PPeerManager
{
    P2PServerNode   *_serverInstance;           // Us broadcasting to others that we offer a service
    
    NSMutableSet *_activePeers;           // Peers we are connected to and ready to interact with
//    NSMutableSet *_inactivePeers;         // Peers that are no longer connected (for debugging)
    
    NSNetServiceBrowser *_serviceBrowser;   // Searches for peers
    
//#if !TARGET_OS_IPHONE
//    NSSocketPort        *_socket;
//#endif
    
//    NSNetService        *_service;
//    struct sockaddr     *_addr;
//    int                 _port;
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
	_serverInstance = [[P2PServerNode alloc] initWithInputStream:nil outputStream:nil displayableName:@"Server Node"];
    [_serverInstance beginBroadcasting];
    
    // Find some peeps
//    _allPeers = [[NSMutableSet alloc] init];
    _activePeers = [[NSMutableSet alloc] init];
    [self beginSearching];
//    [self beginBroadcasting];
}

- (void)cleanup
{
    [_serviceBrowser stop];
    [_serverInstance cleanup];
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
        [_serviceBrowser searchForServicesOfType:P2P_BONJOUR_SERVICE_TYPE
                                        inDomain:P2P_BONJOUR_SERVICE_DOMAIN];
    }
}

//- (void)beginBroadcasting
//{
//#if !TARGET_OS_IPHONE
//    _socket = [[NSSocketPort alloc] init];
//    
//    if ( _socket != nil )
//    {
//        _addr = (struct sockaddr *)[[_socket address] bytes];
//        
//        if ( _addr->sa_family == AF_INET )
//        {
//            _port = ntohs(((struct sockaddr_in *)_addr)->sin_port);
//        }
//        else if ( _addr->sa_family == AF_INET6 )
//        {
//            _port = ntohs(((struct sockaddr_in6 *)_addr)->sin6_port);
//        }
//        else
//        {
//            _socket = nil;
//            P2PLog( P2PLogLevelError, @"The family is neither IPv4 nor IPv6. Can't handle." );
//        }
//    }
//    else
//    {
//        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSSocketPort object." );
//    }
//    if ( socket == nil )
//    {
//        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSSocketPort object." );
//        return;
//    }
//#endif
//    
//    
//    
//    
//    _service = [[NSNetService alloc] initWithDomain:P2P_BONJOUR_SERVICE_DOMAIN
//                                               type:P2P_BONJOUR_SERVICE_TYPE
//                                               name:P2P_BONJOUR_SERVICE_NAME
//                                               port:P2P_BONJOUR_SERVICE_PORT];
//    
//    if ( _service != nil)
//    {
//        [_service setDelegate:self];
//        [_service publishWithOptions:NSNetServiceListenForConnections];
//    }
//    else
//    {
//        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSNetService object." );
//    }
//}

//- (void)netServiceWillPublish:(NSNetService *)netService
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeWillStartNotification object:self];
//}
//
//- (void)netServiceDidPublish:(NSNetService *)sender
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeDidStartNotification object:self];
//    assert( sender == _serverInstance );
//}

//- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeFailedToStartNotification object:self];
//    P2PLog( P2PLogLevelError, @"%@ - failed to publish: %@", self, [errorDict objectForKey:NSNetServicesErrorCode] );
//}

//- (void)netServiceWillResolve:(NSNetService *)sender
//{
//    LogSelector();
//}
//
//- (void)netServiceDidResolveAddress:(NSNetService *)sender
//{
//    LogSelector();
//}
//
//- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
//{
//    LogSelector();
//}
//
//- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
//{
//    LogSelector();
//}
//
//- (void)netServiceDidStop:(NSNetService *)netService
//{
//    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeDidStopNotification object:self];
//}

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
        if ( [aNetService getInputStream:&inStream outputStream:&outStream] )
        {
            P2PLog( P2PLogLevelNormal, @"%@ - Successfully connected to node's I/O streams", self);
            
            P2PNode *node = [[P2PNode alloc] initWithInputStream:inStream outputStream:outStream displayableName:aNetService.name];
            [_activePeers addObject:node];
            [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
//            node.delegate = self;
//            [node preparePeer];
        }
        else
        {
            P2PLog( P2PLogLevelWarning, @"%@ - Failed to connect to node's I/O streams" );
        }
    }
    
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
#warning Take another look at this
//    if ( [aNetService.type isEqualToString:P2P_BONJOUR_SERVICE_TYPE] )
//    {
//        // Find a good way to do this
//        P2PLog( P2PLogLevelNormal, @"******** DID LOSE PEER: %@ NEED TO HANDLE **********", aNetService.name );
//        for ( P2PPeerNode *peer in _activePeers )
//        {
//            if ( peer.netService == aNetService )
//            {
//                [self peerIsNoLongerReady:peer];
//            }
//        }
//    }
}

//- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
//{
//    P2PLogDebug( @"*** A peer has connected to our server" );
//    [self takeOverInputStream:inputStream outputStream:outputStream];
//}




//#pragma mark - P2PPeer Delegate Methods
//- (void)peerDidBecomeReady:(P2PPeerNode *)peer
//{
//    P2PLogDebug( @"%@ - peer did become ready", peer );
//    [_activePeers addObject:peer];
//    [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
//}
//
//- (void)peerIsNoLongerReady:(P2PPeerNode *)peer
//{
//    P2PLogDebug( @"%@ - peer is no longer ready", peer );
//    [_activePeers removeObject:peer];
//    [[NSNotificationCenter defaultCenter] postNotificationName:P2PPeerManagerPeerListUpdatedNotification object:self];
//}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@>", [self class]];
}

@end
