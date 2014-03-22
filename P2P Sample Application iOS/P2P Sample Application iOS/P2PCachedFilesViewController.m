//
//  P2PCachedFilesViewController.m
//  P2P Sample Application iOS
//
//  Created by Tyler Darby on 2/27/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PCachedFilesViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "P2PFileManager.h"
#import "P2PFileRequest.h"
#import "P2PAddFileViewController.h"
#import "P2PFileInfoViewController.h"
#import "P2PFileInfo.h"
#import "P2PFileInCacheTableViewCell.h"

#define kNumberOfTableSections                      1

static NSString *FilesInCacheCellIdentifier =       @"P2PFilesInCacheCell";
static NSString *ActiveTransfersCellIdentifier =    @"P2PActiveTransfersCell";


@interface P2PCachedFilesViewController () <P2PAddFileViewControllerDelegate, P2PFileRequestDelegate, P2PFileInfoDelegate>

@end

@implementation P2PCachedFilesViewController
@synthesize headerView = _headerView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CALayer *bottomBorder = [CALayer layer];
    
    bottomBorder.frame = CGRectMake(0.0f, 63.0f, _headerView.frame.size.width, 1.0f);
    
    bottomBorder.backgroundColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    [_headerView.layer addSublayer:bottomBorder];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfTableSections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Files on disk";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%lu files", (unsigned long)[[[P2PFileManager sharedManager] allFileIds] count]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[P2PFileManager sharedManager] allFileIds] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    P2PFileInCacheTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FilesInCacheCellIdentifier];
    assert( cell != nil );
    
    NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:indexPath.row];
    cell.fileInfo = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( editingStyle == UITableViewCellEditingStyleDelete )
    {
        P2PFileInCacheTableViewCell *cell = (P2PFileInCacheTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        assert( [cell isMemberOfClass:[P2PFileInCacheTableViewCell class]] );
                 
        [[P2PFileManager sharedManager] deleteFileFromCache:cell.fileInfo];
        [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.destinationViewController isKindOfClass:[P2PAddFileViewController class]] )
    {
        ((P2PAddFileViewController *)segue.destinationViewController).delegate = self;
    }
    else if ( [segue.destinationViewController isKindOfClass:[P2PFileInfoViewController class]] )
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *currentId = [[[P2PFileManager sharedManager] allFileIds] objectAtIndex:indexPath.row];
        P2PFileInfo *info = [[P2PFileManager sharedManager] fileInfoForFileId:currentId filename:nil];

        ((P2PFileInfoViewController *)segue.destinationViewController).fileInfo = info;
    }
}

#pragma mark - Add File View Controller Delegate Methods
- (void)addFileController:(P2PAddFileViewController *)controller didSelectFileToAdd:(NSString *)filename
{
    P2PFileRequest *request = [[P2PFileRequest alloc] initWithFilename:filename];
    request.delegate = self;
    request.fileInfo.delegate = self;
    [request getFile];
    
    [self.tableView reloadData];
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - File Request Delegate Methods
- (void)fileRequest:(P2PFileRequest *)fileRequest didRecieveChunk:(P2PFileChunk *)chunk
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)fileRequest:(P2PFileRequest *)fileRequest didFindMultipleIds:(NSArray *)fileIds forFileName:(NSString *)filename
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)fileRequestDidComplete:(P2PFileRequest *)fileRequest
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}

- (void)fileRequestDidFail:(P2PFileRequest *)fileRequest withError:(P2PFileRequestError)errorCode
{
    NSLog( @"%@", NSStringFromSelector(_cmd) );
}


#pragma mark - FileInfo Delegate Methods
- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksAvailableFromPeers:(NSUInteger)chunksAvailable
{
    // Not handled here
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateChunksOnDisk:(NSUInteger)chunksOnDisk
{
    // Not handled here
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateFileId:(NSString *)fileId filename:(NSString *)filename
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)fileInfo:(P2PFileInfo *)fileInfo didUpdateTotalChunks:(NSUInteger)totalChunks
{
    // Not handled here
}

@end
