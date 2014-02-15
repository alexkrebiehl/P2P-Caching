//
//  NSObject+cleanup.h
//  P2PCache
//
//  Created by Alex Krebiehl on 2/14/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (cleanup)

/** Called when the cache is about to shut down.  An object recieving this should close any connections,
 close any open files, etc */
- (void)cleanup;

@end
