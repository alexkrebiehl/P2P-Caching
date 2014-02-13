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
#import "P2PNetworkTool.h"
#import "P2PPeerFileAvailibilityRequest.h"

@interface P2PPeerServer ()//<P2PIncomingDataDelegate>

@end


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
    
    
//    NSMutableData *_inStreamBuffer;
//    
//    
//    NSMutableArray *_activeDataTransfers;   // An array of P2PIncomingData objects
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
                                                   port:P2P_BONJOUR_SERVICE_PORT];
        
//        if ( [_service getInputStream:&_inputStream outputStream:&_outputStream] )
//        {
//            _inputStream.delegate = self;
//            [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//            [_inputStream open];
//            
//            _outputStream.delegate = self;
//            [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//            [_outputStream open];
//            P2PLog( P2PLogLevelDebug, @"SERVER service has stream references" );
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

- (void)handleRecievedObject:(id)object from:(P2PNode *)sender;
{
    NSLog(@"%@ recieved %@ from %@", self, object, sender);
    
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

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    NSLog(@"******* P2P SERVER DID ACCEPT STREAM CONNECTION ******");
    [self takeOverInputStream:inputStream outputStream:outputStream forService:sender];
    
//    inputStream.delegate = self;
//    [inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//    [inputStream open];
//    
//    outputStream.delegate = self;
//    [outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//    [outputStream open];
}

//#pragma mark - NSStream Delegate Methods
//- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
//{
//    switch ( eventCode )
//    {
//        case NSStreamEventHasBytesAvailable:
//        {
//            NSLog(@"SERVER NSStreamEventHasBytesAvailable");
//            
//            assert([aStream isKindOfClass:[NSInputStream class]]);
//            P2PIncomingData *d = [[P2PIncomingData alloc] initWithInputStream:((NSInputStream *)aStream)];
//            
//            if ( _activeDataTransfers == nil )
//            {
//                _activeDataTransfers = [[NSMutableArray alloc] init];
//            }
//            
//            [_activeDataTransfers addObject:d];
//            d.delegate = self;
//            [d takeOverStream];
//            
//            break;
//        }
//        case NSStreamEventEndEncountered:
//        {
//            NSLog(@"SERVER NSStreamEventEndEncountered");
//            //[self closeStreams];
//            break;
//        }
//        case NSStreamEventHasSpaceAvailable:
//        {
//            NSLog(@"SERVER %@ NSStreamEventHasSpaceAvailable", aStream);
//            break;
//        }
//        case NSStreamEventErrorOccurred:
//        {
//            NSLog(@"SERVER NSStreamEventErrorOccurred");
//            break;
//        }
//        case NSStreamEventOpenCompleted:
//        {
//            NSLog(@"SERVER %@ NSStreamEventOpenCompleted", aStream);
//            break;
//        }
//        case NSStreamEventNone:
//        {
//            NSLog(@"SERVER NSStreamEventNone");
//        }
//        default:
//            break;
//    }
//    
//}
//
//
//#pragma mark - P2PIncomingDataDelegate
//- (void)dataDidFinishLoading:(P2PIncomingData *)loader
//{
//    NSLog(@"download finished: %@", loader );
//    [_activeDataTransfers removeObject:loader];
//    
//    
//    switch ( loader.type )
//    {
//        case P2PNetworkTransmissionTypeObject:
//        {
//            id obj = [NSKeyedUnarchiver unarchiveObjectWithData:loader.downloadedData];
//            NSLog(@"recieved object: %@", obj);
//            break;
//        }
//        case P2PNetworkTransmissionTypeData:
//        {
//            NSLog(@"recieved data: %@", loader.downloadedData);
//            break;
//        }
//        case P2PNetworkTransmissionTypeUnknown:
//        default:
//            NSAssert(NO, @"Unknown file recieved");
//            break;
//    }
//}
//
///** If we have an incoming object from a data transfer, it will be sent here so we can figure out
// what to do with it */
//- (void)dispatchRecievedObject:(id)object
//{
//    if ( [object isMemberOfClass:[P2PPeerFileAvailibilityRequest class]] )
//    {
//        
//    }
//}


@end
