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
#import "P2PFileManager.h"
#import "P2PFileRequest.h"

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
    NSUInteger numPeers = [[[P2PPeerManager sharedManager] activePeers] count];
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

- (IBAction)requestFileButtonPressed:(id)sender
{
    P2PFileRequest *request = [P2PCache requestFileWithName:@"this_is_a_test.jpg"];
    [request getFile];
    
}
- (IBAction)addFileToCacheButtonPressed:(id)sender
{
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    // Enable options in the dialog.
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:YES];
    
    if ( [openDlg runModal] == NSOKButton )
    {
        // Gets list of all files selected
        NSArray *files = [openDlg URLs];
        for ( NSURL *file in files )
        {
            NSData *fileData = [NSData dataWithContentsOfURL:file];
            NSString *fileName = [[P2PFileManager sharedManager] displayNameAtPath:[file absoluteString]];
            [[P2PFileManager sharedManager] cacheFile:fileData withFileName:fileName];
        }
    }
   
}
@end
