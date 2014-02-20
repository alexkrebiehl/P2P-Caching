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
#import "P2PFilesInCacheWindowController.h"
#import "P2PPeerListWindowController.h"
//#import "P2PServerNode.h"

@interface P2PAppDelegate () <P2PFileRequestDelegate, NSToolbarDelegate>

@end

@implementation P2PAppDelegate
{
    P2PFilesInCacheWindowController *_filesInCacheWindowController;
    P2PPeerListWindowController *_peerListWindowController;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peersUpdatedNotification:)
                                                 name:P2PPeerManagerPeerListUpdatedNotification
                                               object:nil];
    
    
    [self registerForServerStatusNotifications];
    [self setupToolbar];
    
    // Server Status
    
    [P2PCache start];
}

- (void)setupToolbar
{
    [self.window.toolbar setDelegate:self];
    for ( NSToolbarItem *item in [self.window.toolbar items] )
    {
        if ( [item.itemIdentifier isEqualToString:@"P2PMainWindowActiveRequestsButton"] )
        {
            [item setAction:@selector(activeRequestsButtonPressed)];
        }
        else if ( [item.itemIdentifier isEqualToString:@"P2PMainWindowLogButton"] )
        {
            [item setAction:@selector(logButtonPressed)];
        }
        else if ( [item.itemIdentifier isEqualToString:@"P2PMainWindowPeerListButton"] )
        {
            [item setAction:@selector(peerListButtonPressed)];
        }
        else if ( [item.itemIdentifier isEqualToString:@"P2PMainWindowFilesInCacheButton"] )
        {
            [item setAction:@selector(filesInCacheButtonPressed)];
        }
        else if ( [item.itemIdentifier isEqualToString:@"P2PMainWindowStatsButton"] )
        {
            [item setAction:@selector(statsButtonPressed)];
        }
    }
}

//- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
//{
//    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
//    [item setTarget:self];
//    
//
//    
////    P2PMainWindowActiveRequestsButton
////    P2PMainWindowLogButton
////    P2PMainWindowPeerListButton
////    P2PMainWindowFilesInCacheButton
////    P2PMainWindowStatsButton
//    return item;
//}

- (void)activeRequestsButtonPressed
{
    NSLog(@"active button");
}

- (void)logButtonPressed
{
    
}

- (void)peerListButtonPressed
{
    if ( _peerListWindowController == nil )
    {
        _peerListWindowController = [[P2PPeerListWindowController alloc] initWithWindowNibName:@"P2PPeerListWindowController"];
    }
    
    [_peerListWindowController showWindow:self];
}

- (void)filesInCacheButtonPressed
{
    if ( _filesInCacheWindowController == nil )
    {
        _filesInCacheWindowController = [[P2PFilesInCacheWindowController alloc] initWithWindowNibName:@"P2PFilesInCacheWindowController"];
    }
    
    [_filesInCacheWindowController showWindow:self];
}

- (void)statsButtonPressed
{
    
}

- (void)registerForServerStatusNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverWillStartNotification:) name:P2PServerNodeWillStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStartNotification:) name:P2PServerNodeDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverDidStopNotification:) name:P2PServerNodeDidStopNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serverFailedToStartNotification:) name:P2PServerNodeFailedToStartNotification object:nil];
}

- (void)peersUpdatedNotification:(NSNotification *)notification
{
    NSUInteger numPeers = [[[P2PPeerManager sharedManager] activePeers] count];
    [self.peersFoundLabel setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)numPeers]];
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
    P2PFileRequest *request = [P2PCache requestFileWithName:@"library.jpg"];
    request.delegate = self;
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


- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - Server Status Updates
- (void)serverWillStartNotification:(NSNotification *)notificaiton
{
    [self.serverStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
}

- (void)serverDidStartNotification:(NSNotification *)notification
{
    [self.serverStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
}

- (void)serverFailedToStartNotification:(NSNotification *)notification
{
    [self.serverStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
}

- (void)serverDidStopNotification:(NSNotification *)notification
{
    [self.serverStatusIcon setImage:[NSImage imageNamed:NSImageNameStatusNone]];
}

@end
