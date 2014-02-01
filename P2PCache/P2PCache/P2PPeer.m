//
//  P2PPeer.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//



#import "P2PPeer.h"
#import "SimplePing.h"

@interface P2PPeer()<SimplePingDelegate>

// Private Properties
@property (nonatomic, strong) NSDate *lastPingSentTime;     // Track how long the ping took
@property (nonatomic, strong) SimplePing *pinger;           // Object pinging the peer
@property (nonatomic, strong) NSTimer *peerResponseTimer;   // Timer running the reoccouring pings

@end


@implementation P2PPeer

- (id)init
{
    return [self initWithIpAddress:nil port:0 domain:nil];
}

/* Designated initializer */
- (id)initWithIpAddress:(NSString *)ipAddress port:(NSUInteger)port domain:(NSString *)domain
{
    if ( self = [super init] )
    {
        NSAssert(ipAddress != nil, @"Must supply an IP Address");
        NSAssert(port != 0, @"Must provide a valid port");
        
        _ipAddress = ipAddress;
        _port = port;
        _domain = domain;
        
        _responseTime = P2PPeerNoResponse;
        [self updateResponseTime];
        [self startUpdatingResponseTime];
    }
    return self;
}




- (void)startUpdatingResponseTime
{
    // Dont do anything if there is already a timer going
    if ( _peerResponseTimer == nil )
    {
        NSLog(@"%@ - starting ping loop", self);
        _responseTime = P2PPeerNoResponse;
        
        
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:P2P_PEER_RESPONSE_INTERVAL
                                                          target:self
                                                        selector:@selector(updateResponseTime)
                                                        userInfo:nil
                                                         repeats:YES];
        
        // The tolerance allows the system to slightly vary when it fires our timer
        // in order to have the least ammount of battery impact.
        // ex 10 second timer with 10% tolerence will actually fire every 9-11 seconds
        [timer setTolerance:P2P_PEER_RESPONSE_INTERVAL * P2P_PEER_RESPONSE_INTERVAL_TOLERANCE];
        
        _peerResponseTimer = timer;
        _pinger = [SimplePing simplePingWithHostName:self.ipAddress];
        _pinger.delegate = self;
        [_pinger start];
        
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopUpdatingResponseTime
{
    if ( _peerResponseTimer != nil )
    {
        NSLog(@"%@ - stopping ping", self);
        [_peerResponseTimer invalidate];
        _peerResponseTimer = nil;
        _responseTime = P2PPeerNoResponse;
        
        [_pinger stop];
        _pinger = nil;
    }
}

- (void)updateResponseTime
{
    NSLog(@"%@ ping", self);
    _lastPingSentTime = [NSDate new];
    [_pinger sendPingWithData:nil];
}



#pragma mark - SimplePing Delegate Methods
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address
{
    NSLog(@"%@ - ready to start pinging", self);
    [self updateResponseTime];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet
{
    _responseTime = ABS([_lastPingSentTime timeIntervalSinceNow]) * 1000;
    _lastPingSentTime = nil;
    
    NSLog(@"Ping response: %fms", self.responseTime);
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error
{
    NSLog(@"%@ - ping failed: %@", self, error);
    _responseTime = P2PPeerNoResponse;
    _lastPingSentTime = nil;
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error
{
    NSLog(@"%@ - ping failed: %@", self, error);
    _responseTime = P2PPeerNoResponse;
    _lastPingSentTime = nil;
}






#pragma mark - Logging
- (NSString *)description
{
    NSString *r = self.responseTime == P2PPeerNoResponse ? @"No Response" : [NSString stringWithFormat:@"%lums", (unsigned long)self.responseTime];
    return [NSString stringWithFormat:@"<%@: %@:%lu -> %@>", NSStringFromClass([self class]), self.ipAddress, (unsigned long)self.port, r];
}

@end
