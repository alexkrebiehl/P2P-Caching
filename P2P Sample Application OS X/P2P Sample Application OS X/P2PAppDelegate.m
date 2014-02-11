//
//  P2PAppDelegate.m
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PAppDelegate.h"
#import "P2PCache/P2PCache.h"
#import "P2PPeerManager.h"

@implementation P2PAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peersUpdatedNotification:)
                                                 name:P2PPeerManagerPeerListUpdatedNotification
                                               object:nil];
    [P2PCache start];
}

- (void)peersUpdatedNotification:(NSNotification *)notification
{
    NSUInteger numPeers = [[[P2PPeerManager sharedManager] peerList] count];
    [self.peersFoundLabel setStringValue:[NSString stringWithFormat:@"Peers found: %lu", (unsigned long)numPeers]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [P2PCache shutdown];
    
    return NSTerminateNow;
}

@end
