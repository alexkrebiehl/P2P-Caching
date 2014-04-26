//
//  P2PServerNode.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//
//  Information on how to construct this service was taken from http://blog.haurus.com/?p=342
//




/**
    This Bonjour Server is "us" telling the rest of the network that we offer P2P services
 */

#import "P2PServerNode.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import "P2PPeerFileAvailibilityRequest.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PFileManager.h"
#import "P2PFileChunk.h"
#import "P2PFileChunkRequest.h"
#import "P2PNodeConnection.h"

@interface P2PServerNode ()

@end


@implementation P2PServerNode
{
#if !TARGET_OS_IPHONE
    NSSocketPort        *_socket;
#endif
    
    NSNetService        *_service;
    struct sockaddr     *_addr;
    int                 _port;
    
    NSMutableSet *_activeConnections;
}

- (void)beginBroadcasting
{
#if !TARGET_OS_IPHONE
    _socket = [[NSSocketPort alloc] init];
    
    if ( _socket != nil )
    {
        _addr = (struct sockaddr *)[[_socket address] bytes];
        
        if ( _addr->sa_family == AF_INET )
        {
            _port = ntohs(((struct sockaddr_in *)_addr)->sin_port);
        }
        else if ( _addr->sa_family == AF_INET6 )
        {
            _port = ntohs(((struct sockaddr_in6 *)_addr)->sin6_port);
        }
        else
        {
            _socket = nil;
            P2PLog( P2PLogLevelError, @"The family is neither IPv4 nor IPv6. Can't handle." );
        }
    }
    else
    {
        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSSocketPort object." );
    }
    if ( socket == nil )
    {
        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSSocketPort object." );
        return;
    }
#endif

    _service = [[NSNetService alloc] initWithDomain:P2P_BONJOUR_SERVICE_DOMAIN
                                               type:P2P_BONJOUR_SERVICE_TYPE
                                               name:P2P_BONJOUR_SERVICE_NAME
                                               port:P2P_BONJOUR_SERVICE_PORT];
    
    if ( _service != nil)
    {
        [_service setDelegate:self];
        [_service publishWithOptions:NSNetServiceListenForConnections];
    }
    else
    {
        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSNetService object." );
    }
}

#pragma mark - NSNetServiceDelegate
- (void)netServiceWillPublish:(NSNetService *)netService
{
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeWillStartNotification object:self];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeDidStartNotification object:self];
    assert( sender == _service );
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeFailedToStartNotification object:self];
    P2PLog( P2PLogLevelError, @"%@ - failed to publish: %@", self, [errorDict objectForKey:NSNetServicesErrorCode] );
}

- (void)netServiceDidStop:(NSNetService *)netService
{
    [[NSNotificationCenter defaultCenter] postNotificationName:P2PServerNodeDidStopNotification object:self];
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    P2PLogDebug( @"%@ - A peer has connected to our server: %@", self, sender.name );
    
    if ( _activeConnections == nil )
    {
        _activeConnections = [[NSMutableSet alloc] init];
    }
    
    P2PNodeConnection *newConnection = [[P2PNodeConnection alloc] initWithInputStream:inputStream outputStream:outputStream];
    newConnection.delegate = self;
    [newConnection openConnection];
    [_activeConnections addObject:newConnection];
}

#pragma mark - Misc
- (void)cleanup
{
    [super cleanup];
    [_service stop];
    
    for ( P2PNodeConnection *connection in _activeConnections )
    {
        [connection dropConnection];
    }
}

@end
