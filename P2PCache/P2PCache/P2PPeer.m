//
//  P2PPeer.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/31/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//



#import "P2PPeer.h"

@implementation P2PPeer
{
    NSTimer *_peerResponseTimer;    // Timer running the reoccouring pings
}



- (id)init
{
    return [self initWithIpAddress:nil];
}

/* Designated initializer */
- (id)initWithIpAddress:(NSString *)ipAddress
{
    if ( self = [super init] )
    {
        NSAssert(ipAddress != nil, @"Must supply an IP Address");
        _ipAddress = ipAddress;
        
        _responseTime = P2PPeerNoResponse;
        [self startUpdatingResponseTime];
    }
    return self;
}




- (void)startUpdatingResponseTime
{
    // Dont do anything if there is already a timer going
    if ( _peerResponseTimer == nil )
    {
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
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)stopUpdatingResponseTime
{
    if ( _peerResponseTimer != nil )
    {
        [_peerResponseTimer invalidate];
        _peerResponseTimer = nil;
        _responseTime = P2PPeerNoResponse;
    }
}

- (void)updateResponseTime
{
    // Ping the peer here
}

@end
