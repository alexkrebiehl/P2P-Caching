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

@interface P2PServerNode ()

@end


@implementation P2PServerNode
{
    NSSocketPort        *_socket;
    NSNetService        *_service;
    struct sockaddr     *_addr;
    int                 _port;
}

- (id)init
{
    if ( self = [super init] )
    {
        
    }
    return self;
}

- (void)beginBroadcasting
{
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
    
    
    
    if ( socket != nil )
    {
        
        
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
    else
    {
        P2PLog( P2PLogLevelError, @"An error occurred initializing the NSSocketPort object." );
    }
}

- (void)handleRecievedObject:(id)object from:(NSNetService *)sender
{   
    if ( [object isMemberOfClass:[P2PPeerFileAvailibilityRequest class]] )
    {
        // Check file availbility
        P2PPeerFileAvailbilityResponse *response = [[P2PFileManager sharedManager] fileAvailibilityForRequest:object];
        
        [self transmitObject:response toNetService:sender]; 
    }
    else
    {
        NSAssert( NO, @"Recieved unexpected file" );
    }
    
}


#pragma mark - NSNetServiceDelegate

- (void)netServiceWillPublish:(NSNetService *)netService
{
    LogSelector();
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    LogSelector();
    assert( sender == _service );
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    LogSelector();
    assert(NO); // For debugging... find out why we did not publish
}

- (void)netServiceWillResolve:(NSNetService *)sender
{
    LogSelector();
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    LogSelector();
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    LogSelector();
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
    LogSelector();
}

- (void)netServiceDidStop:(NSNetService *)netService
{
    LogSelector();
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    // Note to self for the next time I work on this:
    // 'sender' is our local server instance, not the netservice of the connecting peer
    
    P2PLogDebug( @"*** %@ has connected to our server", sender.name );
    [self takeOverInputStream:inputStream outputStream:outputStream forService:sender];
}

#pragma mark - Logging
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), _service.name];//, (unsigned long)self.port, r];
}

@end
