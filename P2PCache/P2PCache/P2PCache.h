//
//  P2PCache.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface P2PCache : NSObject

/** Where the fun starts */
+ (void)start;

/** Power down, captain */
+ (void)shutdown;

@end
