//
//  NSObject+cleanup.m
//  P2PCache
//
//  Created by Alex Krebiehl on 2/14/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "NSObject+cleanup.h"

@implementation NSObject (cleanup)

- (void)cleanup
{
    // Default implementation does nothing
    NSLog( P2PLogLevelDebug, @"<%@> cleaning up", self );
}

@end
