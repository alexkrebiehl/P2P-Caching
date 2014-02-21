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
#import "P2PPeerNode.h"
#import "P2PActiveTransfersWindowController.h"
//#import "P2PServerNode.h"

@interface P2PAppDelegate () <NSToolbarDelegate>

@end

@implementation P2PAppDelegate
{
    P2PFilesInCacheWindowController *_filesInCacheWindowController;
    P2PActiveTransfersWindowController *_activeFilesController;
    
    NSMutableOrderedSet *_allPeers;  // A list of peers, including ones that have disconnected
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(peersUpdatedNotification:)
                                                 name:P2PPeerManagerPeerListUpdatedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activeFileRequestsUpdated:) name:P2PActiveFileRequestsDidChange
                                               object:nil];
    
    [self registerForServerStatusNotifications];
    [self setupToolbar];

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
            [item setAction:@selector(peerListButtonPressed:)];
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

- (void)activeRequestsButtonPressed
{
    if ( _activeFilesController == nil )
    {
        _activeFilesController = [[P2PActiveTransfersWindowController alloc] initWithWindowNibName:@"P2PActiveTransfersWindowController"];
    }
    
    [_activeFilesController showWindow:self];
}

- (void)logButtonPressed
{
    
}

- (void)peerListButtonPressed:(NSToolbarItem *)sender
{
    self.peerDrawer.contentSize = CGSizeMake(200, 0);
    [self.peerDrawer toggle:self];
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
    NSArray *activePeers = [[P2PPeerManager sharedManager] activePeers];
    if ( _allPeers == nil )
    {
        _allPeers = [[NSMutableOrderedSet alloc] initWithArray:activePeers copyItems:NO];
    }
    else
    {
        [_allPeers addObjectsFromArray:activePeers];
    }
    [self.peerListTableView reloadData];
    [self.peersFoundLabel setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)[activePeers count]]];
}

- (void)activeFileRequestsUpdated:(NSNotification *)notification
{
    self.activeRequestsLabel.stringValue = [NSString stringWithFormat:@"%lu", [[P2PFileRequest pendingFileRequests] count]];
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


#pragma mark - Peer table view delegate/datasource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_allPeers count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSView *view;
    P2PPeerNode *peer = [_allPeers objectAtIndex:row];
    if ( [tableColumn.identifier isEqualToString:@"P2PPeerTableStatusColumn"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PPeerTableStatusCell" owner:self];
        NSImageView *statusIcon = [view viewWithTag:0];
        
        if ( [[[P2PPeerManager sharedManager] allPeers] containsObject:peer] )
        {
            [statusIcon setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
        }
        else
        {
            [statusIcon setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
        }
        
        
    }
    else if ( [tableColumn.identifier isEqualToString:@"P2PPeerTableNameColumn"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PPeerTableNameCell" owner:self];
        NSTextField *text = [view viewWithTag:0];
        text.stringValue = peer.netService.name;
    }
    return view;
}


@end
