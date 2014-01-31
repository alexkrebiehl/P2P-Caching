//
//  P2PLogging.h
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LOG_TO_CONSOLE  YES
#define LOG_TO_FILE     YES
#define LOG_DATE_FORMAT @"MM-dd-yy HH:mm:ss"


/** Logging Levels.  Will only log levels greater than or equal to logLevel */
typedef NS_ENUM( NSInteger, P2PLogLevel )
{
    P2PLogLevelDebug = 0,   // Debugging Messages
    P2PLogLevelWarning,     // Warnings
    P2PLogLevelError,       // Bad things happened
};
#define LOG_LEVEL_ALL INT_MIN

/** Currently set logging level */
static const P2PLogLevel logLevel = LOG_LEVEL_ALL;

/** Log status messages to the console and/or file */
extern void P2PLog( P2PLogLevel level, NSString *message, ... );
