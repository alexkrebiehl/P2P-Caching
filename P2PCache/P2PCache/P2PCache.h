//
//  P2PCache.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *P2PServerNodeWillStartNotification;
extern NSString *P2PServerNodeDidStartNotification;
extern NSString *P2PServerNodeFailedToStartNotification;
extern NSString *P2PServerNodeDidStopNotification;


//static NSString *P2PCacheShutDownSignalRecievedNotification = @"P2PCacheShutDownSignalRecievedNotification";

@class P2PFileRequest;

@interface P2PCache : NSObject

/** Where the fun starts */
+ (void)start;

/** Power down, captain */
+ (void)shutdown;

/** We probably wont do it this way down the road, but it will make initial testing easier */
+ (P2PFileRequest *)requestFileWithName:(NSString *)filename;

@end
