//
//  P2PAppDelegate.m
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PAppDelegate.h"
#import <P2PCache/P2PCache.h>

@implementation P2PAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [P2PCache start];
}

@end
