//
//  P2PActiveTransfersWindowController.m
//  P2P Sample Application OS X
//
//  Created by Alex Krebiehl on 2/20/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PActiveTransfersWindowController.h"
#import "P2PFileRequest.h"
#import "P2PCache.h"
#import "P2PFileInfo.h"

@interface P2PActiveTransfersWindowController () <P2PFileRequestDelegate>

@end

@implementation P2PActiveTransfersWindowController
{
    NSMutableArray *_allTransfers;
}

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

- (IBAction)requestFileButtonPressed:(id)sender
{
    NSString *fileName = self.fileNameComboBox.stringValue;
    
    if ( fileName == nil || [fileName isEqualToString:@""] )
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"No file name given"];
        [alert setInformativeText:@"Enter name of file to request"];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
    else
    {
        P2PFileRequest *request = [P2PCache requestFileWithName:fileName];
        if ( _allTransfers == nil )
        {
            _allTransfers = [[NSMutableArray alloc] init];
        }
        [_allTransfers insertObject:request atIndex:0];
        [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:0] withAnimation:NSTableViewAnimationSlideDown];
//        [self.tableView reloadData];
        request.delegate = self;
        [request getFile];
    }
}


#pragma mark - File request delegate methods
- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSUInteger index = [_allTransfers indexOfObject:fileRequest];
    [self reloadEntireRowAtIndex:index];
}

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSUInteger index = [_allTransfers indexOfObject:fileRequest];
    [self reloadEntireRowAtIndex:index];
}

- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode
{
    NSString *error;
    switch ( errorCode )
    {
        case P2PFileRequestErrorFileNotFound:
            error = @"file not found";
            break;
        case P2PFileRequestErrorMissingChunks:
            error = @"file missing chunks";
            break;
        case P2PFileRequestErrorMultipleIdsForFile:
            error = @"multiple ids for filename";
            break;
        case P2PFileRequestErrorNone:
        default:
            assert( NO );
            break;
    }
    NSLog(@"File request failed with error: %@", error);
    NSUInteger index = [_allTransfers indexOfObject:fileRequest];
    [self reloadEntireRowAtIndex:index];
}




- (void)reloadEntireRowAtIndex:(NSUInteger)index
{
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.tableView.numberOfColumns)]];
}

#pragma mark - Table view methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_allTransfers count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSView *view;
    P2PFileRequest *request = [_allTransfers objectAtIndex:row];
    if ( [tableColumn.identifier isEqualToString:@"P2PFileTransferColumnStatus"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFileTransferCellStatus" owner:self];
        NSImageView *statusIcon = [view viewWithTag:0];
        
        switch (request.status)
        {
            case P2PFileRequestStatusRetreivingFile:
            case P2PFileRequestStatusCheckingAvailability:
            {
                [statusIcon setImage:[NSImage imageNamed:NSImageNameStatusPartiallyAvailable]];
                break;
            }
            case P2PFileRequestStatusComplete:
            {
                [statusIcon setImage:[NSImage imageNamed:NSImageNameStatusAvailable]];
                break;
            }
            case P2PFileRequestStatusFailed:
            {
                [statusIcon setImage:[NSImage imageNamed:NSImageNameStatusUnavailable]];
                break;
            }
            case P2PFileRequestStatusUnknown:
            case P2PFileRequestStatusNotStarted:
            default:
            {
                [statusIcon setImage:[NSImage imageNamed:NSImageNameStatusNone]];
                break;
            }
        }
    }
    else if ( [tableColumn.identifier isEqualToString:@"P2PFileTransferColumnFilename"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFileTransferCellFilename" owner:self];
        NSTextField *text = [view viewWithTag:0];
        text.stringValue = request.fileInfo.filename;
    }
    else if ( [tableColumn.identifier isEqualToString:@"P2PFileTransferColumnProgress"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFileTransferCellProgress" owner:self];
        NSProgressIndicator *progress = [[view subviews] objectAtIndex:0];
        double newProgress = (((float)[request.fileInfo.chunksOnDisk count] / [request.fileInfo totalChunks]) * 100);
        
        [progress incrementBy:newProgress - progress.doubleValue];
    }
    else if ( [tableColumn.identifier isEqualToString:@"P2PFileTransferColumnAvailable"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFileTransferCellAvailable" owner:self];
        NSTextField *text = [view viewWithTag:0];
        text.stringValue = [NSString stringWithFormat:@"%lu / %lu", request.fileInfo.chunksOnDisk.count, request.fileInfo.chunksAvailable.count];
    }
    else if ( [tableColumn.identifier isEqualToString:@"P2PFileTransferColumnTotal"] )
    {
        view = [tableView makeViewWithIdentifier:@"P2PFileTransferCellTotal" owner:self];
        NSTextField *text = [view viewWithTag:0];
        text.stringValue = [NSString stringWithFormat:@"%lu", request.fileInfo.totalChunks];
    }
    return view;
}


@end
