//
//  P2PPeerManager.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface P2PPeerManager : NSObject

/** A shared manager to handle the tracking of compatable peers */
+ (P2PPeerManager *)sharedManager;

/** Perform setup when the system starts */
- (void)start;

@end
