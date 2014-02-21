//
//  P2PAppDelegate.h
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 1/30/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface P2PAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSImageView *serverStatusIcon;

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *peersFoundLabel;
@property (weak) IBOutlet NSTextField *filesInCacheLabel;
@property (weak) IBOutlet NSTextField *activeRequestsLabel;
@property (weak) IBOutlet NSDrawer *peerDrawer;
@property (weak) IBOutlet NSTableView *peerListTableView;

@end
