//
//  P2PCache.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PCache.h"
#import "P2PCacheProtocol.h"
#import "P2PPeerManager.h"

@implementation P2PCache

+ (void)start
{
    // Ramp-up the Peer Manager
    P2PLog( P2PLogLevelDebug, @"Starting the Peer Manager..." );
    [[P2PPeerManager sharedManager] start];
    
    
    /*  Lets just worry about peer discovery first
    
    // Register our caching protocol with the system
    P2PLog( P2PLogLevelDebug, @"Registering P2P Protocol..." );
    [NSURLProtocol registerClass:[P2PCacheProtocol class]];
     
     */
}

@end
