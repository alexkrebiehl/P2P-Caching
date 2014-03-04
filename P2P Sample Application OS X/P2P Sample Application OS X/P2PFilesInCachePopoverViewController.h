//
//  P2PFilesInCachePopoverViewController.h
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 2/24/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class P2PFileInfo;

@interface P2PFilesInCachePopoverViewController : NSViewController

@property (strong, nonatomic) P2PFileInfo *fileInfo;

@end
