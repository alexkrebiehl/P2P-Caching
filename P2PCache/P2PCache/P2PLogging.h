//
//  P2PLogging.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG_TO_CONSOLE  1
#define LOG_TO_FILE     1
#define LOG_DATE_FORMAT @"HH:mm:ss"    //@"MM-dd-yy HH:mm:ss"


/** Logging Levels.  Will only log levels greater than or equal to LOG_LEVEL */
typedef NS_ENUM( NSInteger, P2PLogLevel )
{
    P2PLogLevelDebug = 0,   // Debugging Messages
    P2PLogLevelNormal,      // General (but useful) messages
    P2PLogLevelWarning,     // Warnings
    P2PLogLevelError,       // Bad things happened
};

/** Currently set logging level */
static const P2PLogLevel LOG_LEVEL = P2PLogLevelNormal;

/** Shortcut for debug log */
void P2PLogDebug( NSString *message, ... ) NS_FORMAT_FUNCTION(1,2);

/** Log status messages to the console and/or file */
extern void P2PLog( P2PLogLevel level, NSString *message, ... ) NS_FORMAT_FUNCTION(2,3);
