//
//  P2PBonjourServer.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <netinet/in.h>
#import <sys/socket.h>

@interface P2PBonjourServer : NSObject <NSNetServiceDelegate,NSStreamDelegate> 

@end
