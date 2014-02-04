//
//  P2PAppDelegate.h
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 1/30/14.
// Some Random Comment. 
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface P2PAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *peersFoundLabel;

@end
