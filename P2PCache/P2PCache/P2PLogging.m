//
//  P2PLogging.m
//  P2PCache
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PLogging.h"

void P2PLogToFile(NSString *message)
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:LOG_DATE_FORMAT];
    
    /* Write logging messages to file here */
//    NSLog(@"[%@] - %@", [formatter stringFromDate:[NSDate new]], message);
}

static NSDateFormatter *_dateFormatter = nil;

void P2PLogDebug( NSString *message, ... )
{
    va_list args;
    va_start(args, message);
    NSString *fullMessage = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);
    P2PLog( P2PLogLevelDebug, @"%@", fullMessage );
}

void P2PLog( P2PLogLevel level, NSString *message, ... )
{
    if ( _dateFormatter == nil )
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:LOG_DATE_FORMAT];
    }
    
    if ( level >= LOG_LEVEL )
    {
        va_list args;
        va_start(args, message);
        NSString *fullMessage = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
        
        
#if LOG_TO_CONSOLE
        printf("[%s] %s\n", [[_dateFormatter stringFromDate:[NSDate new]] UTF8String], [fullMessage UTF8String]);
//        fputs([fullMessage UTF8String], stdout);
//        NSLog(@"%@", fullMessage);
#endif
        
#if LOG_TO_FILE
        P2PLogToFile(fullMessage);
#endif
    }
}

