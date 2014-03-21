//
//  P2PFilesInCacheWindowController.m
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 2/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PFilesInCacheWindowController.h"
#import "P2PFileManager.h"
#import "P2PFileInfo.h"

@interface P2PFilesInCacheWindowController ()

@end

@implementation P2PFilesInCacheWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - Table View Delegate Methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[[P2PFileManager sharedManager] allFileIds] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSView *view;
    NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:row];
    P2PFileInfo *info = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];
    if ( [tableColumn.identifier isEqualToString:@"P2PFilesInCacheFilenameColumn"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFilesInCacheFilenameCell" owner:self];
        NSTextField *text = [view viewWithTag:0];
        text.stringValue = info.filename;
    }
    else if ( [tableColumn.identifier isEqualToString:@"P2PFilesInCacheAvailableColumn"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFilesInCacheAvailableCell" owner:self];
        NSTextField *text = [view viewWithTag:0];
//        NSUInteger chunksAvailable = [[[P2PFileManager sharedManager] availableChunksForFileID:currentId] count];
        text.stringValue = [NSString stringWithFormat:@"%d %%", (int)ceil((([info.chunksAvailable count] / (float)[info totalChunks]) * 100))];
    }
    return view;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    // Might implement drag and drop to add new files
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSUInteger selectedRow = self.tableView.selectedRow;
    NSLog(@"selected row: %lu", selectedRow);
}

@end
