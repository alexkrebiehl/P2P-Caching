//
//  P2PPeer.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//



#import "P2PPeerNode.h"
#import "SimplePing.h"
#import "P2PFileRequest.h"
#import "P2PPeerFileAvailbilityResponse.h"
#import "P2PPeerFileAvailibilityRequest.h"

@interface P2PPeerNode() <NSNetServiceDelegate, NSStreamDelegate>//   <SimplePingDelegate>

// Private Properties
@property (nonatomic, strong) NSDate *lastPingSentTime;     // Track how long the ping took
@property (nonatomic, strong) SimplePing *pinger;           // Object pinging the peer
@property (nonatomic, strong) NSTimer *peerResponseTimer;   // Timer running the reoccouring pings

@end


@implementation P2PPeerNode
{
    NSMutableArray *_pendingFileAvailibilityRequests;
}

- (id)init
{
    return [self initWithNetService:nil];
}

- (id)initWithNetService:(NSNetService *)netService
{
    if ( self = [super init] )
    {
        NSAssert( netService != nil, @"Cannot init with a nil netService!" );
        
        _peerIsReady = NO;
        
        _netService = netService;
        _netService.delegate = self;
    }
    return self;
}

- (void)preparePeer
{
    // Resolve addresses
    [_netService resolveWithTimeout:0];
    
    // open streams
    NSInputStream		*inStream;
    NSOutputStream		*outStream;
    if ( [_netService getInputStream:&inStream outputStream:&outStream] )
    {
        NSLog(@"PEER Successfully connected to peer's stream");
        [self takeOverInputStream:inStream outputStream:outStream forService:_netService];
    }
    else
    {
        P2PLog( P2PLogLevelError, @"***** Failed connecting to server *******" );
        return;
    }
    
}

// Some insight from StackOverflow...
// http://stackoverflow.com/questions/938521/iphone-bonjour-nsnetservice-ip-address-and-port/4976808#4976808
// Convert binary NSNetService data to an IP Address string
- (void)getAddressAndPort
{
    if ( [[_netService addresses] count] > 0 )
    {
        NSData *data = [[_netService addresses] objectAtIndex:0];
        
        char addressBuffer[INET6_ADDRSTRLEN];
        
        memset(addressBuffer, 0, INET6_ADDRSTRLEN);
        
        typedef union
        {
            struct sockaddr sa;
            struct sockaddr_in ipv4;
            struct sockaddr_in6 ipv6;
        } ip_socket_address;
        
        ip_socket_address *socketAddress = (ip_socket_address *)[data bytes];
        
        if ( socketAddress && (socketAddress->sa.sa_family == AF_INET || socketAddress->sa.sa_family == AF_INET6) )
        {
            const char *addressStr = inet_ntop( socketAddress->sa.sa_family,
                                               (socketAddress->sa.sa_family == AF_INET ? (void *)&(socketAddress->ipv4.sin_addr) : (void *)&(socketAddress->ipv6.sin6_addr)),
                                               addressBuffer,
                                               sizeof(addressBuffer));
            
            int port = ntohs(socketAddress->sa.sa_family == AF_INET ? socketAddress->ipv4.sin_port : socketAddress->ipv6.sin6_port);
            
            if ( addressStr && port )
            {
                NSLog(@"Found service at %s:%d", addressStr, port);
                _ipAddress = [NSString stringWithCString:addressStr encoding:NSUTF8StringEncoding];
                _port = port;
                [self peerDidBecomeReady];
            }
        }
    }
    else
    {
        _ipAddress = nil;
        _port = 0;
        [self peerIsNoLongerReady];
    }
}

- (void)handleRecievedObject:(id)object from:(NSNetService *)sender
{
    NSLog(@"PEER NODE recieved object %@", object);
    if ( [object isMemberOfClass:[P2PPeerFileAvailbilityResponse class]] )
    {
        [self didRecieveFileAvailabilityResponse:object];
    }
}

- (void)peerDidBecomeReady
{
    _peerIsReady = YES;
    [self.delegate peerDidBecomeReady:self];
}

- (void)peerIsNoLongerReady
{
    _peerIsReady = NO;
    [self.delegate peerIsNoLongerReady:self];
}

//- (void)recievedDataFromPeer:(NSData *)data
//{
//    id recievedObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    
//    // figure out what to do with the object
//    if ( [recievedObject isMemberOfClass:[P2PPeerFileAvailbilityResponse class]] )
//    {
//        [self didRecieveFileAvailabilityResponse:recievedObject];
//    }
//}


#pragma mark - NetService Delegate Methods
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    [self getAddressAndPort];
}






#pragma mark - File Handling
- (void)getFileAvailabilityForRequest:(P2PFileRequest *)request
{
    if ( _pendingFileAvailibilityRequests == nil )
    {
        _pendingFileAvailibilityRequests = [[NSMutableArray alloc] init];
    }
    
    [_pendingFileAvailibilityRequests addObject:request];
    
    P2PPeerFileAvailibilityRequest *availibilityRequest = [[P2PPeerFileAvailibilityRequest alloc] initWithFileName:request.fileName];

    [self transmitObject:availibilityRequest];
    NSLog(@"File availability request sent to peer: %@", self);
    
}

- (void)didRecieveFileAvailabilityResponse:(P2PPeerFileAvailbilityResponse *)response
{
    // Find out what request this response is for...
    for ( P2PFileRequest *aRequest in _pendingFileAvailibilityRequests )
    {
        //good enough for now..
        if ( [aRequest.fileName isEqualToString:response.fileName] )
        {
            // found the request.....
            [aRequest peer:self didRecieveAvailibilityResponse:response];
            [_pendingFileAvailibilityRequests removeObject:aRequest];
            return;
        }
    }
}











#pragma mark - Logging
- (NSString *)description
{
    NSString *r = self.responseTime == P2PPeerNoResponse ? @"No Response" : [NSString stringWithFormat:@"%lums", (unsigned long)self.responseTime];
    return [NSString stringWithFormat:@"<%@: %@:%lu -> %@>", NSStringFromClass([self class]), self.ipAddress, (unsigned long)self.port, r];
}




/* Designated initializer */
//- (id)initWithIpAddress:(NSString *)ipAddress port:(NSUInteger)port domain:(NSString *)domain
//{
//    if ( self = [super init] )
//    {
//        NSAssert(ipAddress != nil, @"Must supply an IP Address");
//        NSAssert(port != 0, @"Must provide a valid port");
//        
//        _ipAddress = ipAddress;
//        _port = port;
//        _domain = domain;
//        
//        _responseTime = P2PPeerNoResponse;
//        [self updateResponseTime];
//        [self startUpdatingResponseTime];
//    }
//    return self;
//}




//- (void)startUpdatingResponseTime
//{
//    // Dont do anything if there is already a timer going
//    if ( _peerResponseTimer == nil )
//    {
//        NSLog(@"%@ - starting ping loop", self);
//        _responseTime = P2PPeerNoResponse;
//        
//        
//        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:P2P_PEER_RESPONSE_INTERVAL
//                                                          target:self
//                                                        selector:@selector(updateResponseTime)
//                                                        userInfo:nil
//                                                         repeats:YES];
//        
//        // The tolerance allows the system to slightly vary when it fires our timer
//        // in order to have the least ammount of battery impact.
//        // ex 10 second timer with 10% tolerence will actually fire every 9-11 seconds
//        [timer setTolerance:P2P_PEER_RESPONSE_INTERVAL * P2P_PEER_RESPONSE_INTERVAL_TOLERANCE];
//        
//        _peerResponseTimer = timer;
//        _pinger = [SimplePing simplePingWithHostName:self.ipAddress];
//        _pinger.delegate = self;
//        [_pinger start];
//        
//        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//    }
//}
//
//- (void)stopUpdatingResponseTime
//{
//    if ( _peerResponseTimer != nil )
//    {
//        NSLog(@"%@ - stopping ping", self);
//        [_peerResponseTimer invalidate];
//        _peerResponseTimer = nil;
//        _responseTime = P2PPeerNoResponse;
//        
//        [_pinger stop];
//        _pinger = nil;
//    }
//}
//
//- (void)updateResponseTime
//{
//    NSLog(@"%@ ping", self);
//    _lastPingSentTime = [NSDate new];
//    [_pinger sendPingWithData:nil];
//}
//
//
//
//#pragma mark - SimplePing Delegate Methods
//- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
//{
//    NSLog(@"%@ - ready to start pinging", self);
//    [self updateResponseTime];
//}
//
//- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
//{
//    _responseTime = ABS([_lastPingSentTime timeIntervalSinceNow]) * 1000;
//    _lastPingSentTime = nil;
//    
//    NSLog(@"Ping response: %fms", self.responseTime);
//}
//
//- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
//{
//    NSLog(@"%@ - ping failed: %@", self, error);
//    _responseTime = P2PPeerNoResponse;
//    _lastPingSentTime = nil;
//}
//
//- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
//{
//    NSLog(@"%@ - ping failed: %@", self, error);
//    _responseTime = P2PPeerNoResponse;
//    _lastPingSentTime = nil;
//}

@end
