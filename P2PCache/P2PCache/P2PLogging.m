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
    NSLog(@"[%@] - %@", [formatter stringFromDate:[NSDate new]], message);
}

void P2PLog( P2PLogLevel level, NSString *message, ... )
{
    if ( level >= logLevel )
    {
        va_list args;
        va_start(args, message);
        NSString *fullMessage = [NSString stringWithFormat:message, args];
        va_end(args);
        
#if LOG_TO_CONSOLE
        NSLog(@"%@", fullMessage);
#endif
        
#if LOG_TO_FILE
        P2PLogToFile(fullMessage);
#endif
    }
}

