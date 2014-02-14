//
//  P2P.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//
//
//  This file is included on both the OS X and iOS builds
//

#ifndef P2PCache_P2P_h
#define P2PCache_P2P_h

// Bonjour (peer discovery) settings
#define P2P_BONJOUR_SERVICE_DOMAIN  @""  //@"local."
#define P2P_BONJOUR_SERVICE_TYPE    @"_p2pcache._tcp."
#define P2P_BONJOUR_SERVICE_NAME    @"" // Uses machine name for identification
#define P2P_BONJOUR_SERVICE_PORT    0   // Selects random port

// Global imports
#import "Utilities.h"
#import "P2PLogging.h"

// Networking
#import "P2PNode.h"

#endif
