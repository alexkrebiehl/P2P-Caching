//
//  P2PBonjourServer.m
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

#import "P2PBonjourServer.h"
#import <netinet/in.h>
#import <sys/socket.h>


@implementation P2PBonjourServer
{
    NSMutableArray      *_services;
    NSSocketPort        *_socket;
    NSNetService        *_service;
    struct sockaddr     *_addr;
    int                 _port;
    BOOL                _searching;
    NSInputStream		*_inputStream;
	NSOutputStream		*_outputStream;
	BOOL				_inReady;
	BOOL				_outReady;
    NSMutableData       *_dataBuffer;
}

- (id)init
{
    _services = [[NSMutableArray alloc] init];
    _socket = [[NSSocketPort alloc] init];
    _searching = NO;
    
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
        
        if ([_service getInputStream:&_inputStream outputStream:&_outputStream]) {
            P2PLog( P2PLogLevelDebug, @"service has stream references" );
        }
        
        if ( _service != nil)
        {
            [_service setDelegate:self];
            [_service publish];
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
    return self;
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceWillPublish:(NSNetService *)netService {
    NSLog(@"netServiceWillPublish");
    [_services addObject:netService];
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"netServiceDidPublish");
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"didNotPublish");
}

- (void)netServiceWillResolve:(NSNetService *)sender {
    NSLog(@"netServiceWillResolve");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSLog(@"netServiceDidResolveAddress");
}

- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    NSLog(@"didNotResolve");
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    NSLog(@"didUpdateTXTRecordData");
}

- (void)netServiceDidStop:(NSNetService *)netService {
    NSLog(@"netServiceDidStop");
    [_services removeObject:netService];
}


@end
