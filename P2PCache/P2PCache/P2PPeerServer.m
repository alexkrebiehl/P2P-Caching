//
//  P2PPeerServer.m
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

#import "P2PPeerServer.h"
#import <netinet/in.h>
#import <sys/socket.h>


@implementation P2PPeerServer
{
    NSMutableArray      *_services;
    NSSocketPort        *_socket;
    NSNetService        *_service;
    struct sockaddr     *_addr;
    int                 _port;
//    BOOL                _searching;
    NSInputStream		*_inputStream;
	NSOutputStream		*_outputStream;
	BOOL				_inReady;
	BOOL				_outReady;
    NSMutableData       *_dataBuffer;
    
    
    
    
    
    NSMutableData *_inStreamBuffer;
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
    _services = [[NSMutableArray alloc] init];
    _socket = [[NSSocketPort alloc] init];
//    _searching = NO;
    
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
                                                   port:0];
        
//        if ( [_service getInputStream:&_inputStream outputStream:&_outputStream] )
//        {
//            P2PLog( P2PLogLevelDebug, @"service has stream references" );
//        }
        
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

#pragma mark - NSNetServiceDelegate

- (void)netServiceWillPublish:(NSNetService *)netService
{
    LogSelector();
    [_services addObject:netService];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    LogSelector();
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
    LogSelector();
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
    [_services removeObject:netService];
}

static NSInputStream *s = nil;
- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    NSLog(@"******* P2P SERVER DID ACCEPT STREAM CONNECTION ******");
    
    inputStream.delegate = self;
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    
    outputStream.delegate = self;
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream open];
}


#pragma mark - NSStream Delegate Methods
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    NSLog(@"SERVER STREAM EVENT");
    NSInputStream * istream;
    switch ( eventCode )
    {
        case NSStreamEventHasBytesAvailable:
            NSLog(@"SERVER NSStreamEventHasBytesAvailable");
            uint8_t oneByte;
            NSInteger actuallyRead = 0;
            istream = (NSInputStream *)aStream;
            if ( _inStreamBuffer == nil )
            {
                _inStreamBuffer = [[NSMutableData alloc] initWithCapacity:2048];
            }
            actuallyRead = [istream read:&oneByte maxLength:1];
            if (actuallyRead == 1)
            {
                [_inStreamBuffer appendBytes:&oneByte length:1];
            }
            if (oneByte == '\n') {
                // We've got the carriage return at the end of the echo. Let's set the string.
                NSString * string = [[NSString alloc] initWithData:_inStreamBuffer encoding:NSUTF8StringEncoding];
                NSLog(@"p2ppeer recieved data: %@",string);
                _inStreamBuffer = nil;
            }
            break;
        case NSStreamEventEndEncountered:
            NSLog(@"SERVER NSStreamEventEndEncountered");
            //[self closeStreams];
            break;
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"SERVER %@ NSStreamEventHasSpaceAvailable", aStream);
//            [self workOutputBuffer];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"SERVER NSStreamEventErrorOccurred");
            break;
        case NSStreamEventOpenCompleted:
            NSLog(@"SERVER %@ NSStreamEventOpenCompleted", aStream);
            break;
        case NSStreamEventNone:
            NSLog(@"SERVER NSStreamEventNone");
        default:
            break;
    }
    
}


@end
